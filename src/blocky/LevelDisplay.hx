package blocky;

import flambe.Component;
import flambe.Disposer;
import flambe.Entity;
import flambe.System;
import flambe.display.FillSprite;
import flambe.display.Sprite;
import flambe.math.FMath;
import flambe.util.Assert;

import blocky.LevelData;

class LevelDisplay extends Component
{
    public static inline var VIEW_DISTANCE = 10;

    public function new (data :LevelData, maxPixels :Int)
    {
        _level = data;
        _maxPixels = maxPixels;
    }

    override public function onAdded ()
    {
        var worldEntity = new Entity().add(_world = new Sprite());
        owner.addChild(worldEntity);

        _pixels = [];
        for (ii in 0..._maxPixels) {
            var pixel = new PixelDisplay(_level);
            _pixels.push(pixel);
            worldEntity.addChild(pixel.entity);
        }

        var disposer = new Disposer();
        owner.add(disposer);

        disposer.connect1(System.keyboard.down, function (event) {
            if (event.key == Up && _level.player.grounded) {
                _level.player.velY = -8;
            }
        });
        // disposer.add(System.pointer.down.connect(function (event) {
        //     System.stage.requestFullscreen();
        // }).once());
    }

    override public function onRemoved ()
    {
        // TODO
    }

    override public function onUpdate (dt :Float)
    {
        if (System.keyboard.isDown(Left)) {
            _level.player.velX = -5;
        } else if (System.keyboard.isDown(Right)) {
            _level.player.velX = 5;
        } else {
            _level.player.velX = 0;
        }
        _level.update(dt);

        var snapshot = createSnapshot();

        var ii = 0, ll = _maxPixels;
        for (item in snapshot) {
            var found = false;
            for (pixel in _pixels) {
                if (pixel.type != null && Type.enumEq(pixel.type, item.type)) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                switch (item.type) {
                    case Terrain(x, y): playRevealSound(_level.getTerrain(x, y));
                    case Mob(mob): playRevealSound(mob.type);
                }
            }
        }

        var ii = 0, ll = _maxPixels;
        while (ii < ll) {
            var display = _pixels[ii];
            if (ii < snapshot.length) {
                var item = snapshot[ii];
                display.type = item.type;
            } else {
                display.type = null;
            }
            ++ii;
        }

        // Center the camera
        var stageW = System.stage.width, stageH = System.stage.height;
        var viewportX = _level.player.x*PixelDisplay.SCALE - stageW/2;
        var viewportY = _level.player.y*PixelDisplay.SCALE - stageH/2;
        var minX = stageW - _level.width*PixelDisplay.SCALE;
        var minY = stageH - _level.height*PixelDisplay.SCALE;
        _world.x._ = FMath.clamp(-viewportX, -minX, 0);
        _world.y._ = FMath.clamp(-viewportY, -minY, 0);
    }

    private function createSnapshot () :Array<PixelPriority>
    {
        var eyeX = _level.player.x;
        var eyeY = _level.player.y;

        var list = [];
        for (y in 0..._level.height) {
            for (x in 0..._level.width) {
                var priority = _level.getTerrainPriority(x, y);

                var dx = eyeX - x;
                var dy = eyeY - y;
                var distance = Math.sqrt(dx*dx + dy*dy);
                priority *= 5*Math.max(0, VIEW_DISTANCE-distance);

                if (priority > 0) {
                    var idx = findInsertIdx(list, priority);
                    if (idx < _maxPixels) {
                        list.insert(idx, new PixelPriority(Terrain(x, y), priority));
                        if (list.length > _maxPixels) {
                            list.splice(-1, 1); // Trim the excess
                        }
                    }
                }
            }
        }

        for (mob in _level.mobs) {
            var priority = LevelData.toPriority(mob.type);
            var dx = eyeX - mob.x;
            var dy = eyeY - mob.y;
            var distance = Math.sqrt(dx*dx + dy*dy);
            priority *= 5*Math.max(0, VIEW_DISTANCE-distance);

            if (priority > 0) {
                var idx = findInsertIdx(list, priority);
                if (idx < _maxPixels) {
                    list.insert(idx, new PixelPriority(Mob(mob), priority));
                    if (list.length > _maxPixels) {
                        list.splice(-1, 1); // Trim the excess
                    }
                }
            }
        }

        return list;
    }

    private function playRevealSound (block :BlockType)
    {
        // trace("Revealed " + block);
    }

    private static function findInsertIdx (arr :Array<PixelPriority>, priority :Float) :Int
    {
        var left = 0, right = arr.length;
        while (left < right) {
            var middle = Std.int((left+right)/2);
            if (priority < arr[middle].priority) {
                left = middle + 1;
            } else {
                right = middle;
            }
        }
        return left;
    }

    private var _level :LevelData;

    private var _world :Sprite;
    private var _pixels :Array<PixelDisplay>;
    private var _maxPixels :Int;
}

private enum PixelType
{
    Terrain (x :Int, y :Int);
    Mob (mob :Mob);
}

private class PixelPriority
{
    public var type :PixelType;
    public var priority :Float;

    public function new (type :PixelType, priority :Float)
    {
        this.type = type;
        this.priority = priority;
    }
}

private class PixelDisplay
{
    public static inline var SCALE = 20;

    public var type (get, set) :PixelType;
    public var entity :Entity;
    public var sprite :FillSprite;

    public function new (level :LevelData)
    {
        sprite = new FillSprite(0x000000, SCALE, SCALE);
        entity = new Entity().add(sprite);
        _level = level;
        set_type(null);
    }

    private function get_type () return _type;
    private function set_type (type :PixelType) :PixelType
    {
        if (type != null) {
            sprite.visible = true;
            switch (type) {
            case Terrain(x, y):
                sprite.color = getColor(_level.getTerrain(x, y));
                sprite.setXY(x*SCALE, y*SCALE);
            case Mob(mob):
                sprite.color = getColor(mob.type);
                sprite.setXY(mob.x*SCALE - 0.5*SCALE, mob.y*SCALE - 0.5*SCALE);
            }
        } else {
            sprite.visible = false;
        }
        return _type = type;
    }

    private static function getColor (block :BlockType)
    {
        switch (block) {
            case Wall: return 0x000000;
            case Space: Assert.fail(); return 0;
            case Monster: return 0xff0000;
            case Player: return 0x009900;
        }
    }

    private var _type :PixelType;
    private var _level :LevelData;
}
