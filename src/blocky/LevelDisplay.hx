package blocky;

import flambe.Component;
import flambe.Entity;
import flambe.System;
import flambe.display.FillSprite;

import blocky.LevelData;

class LevelDisplay extends Component
{
    public static inline var VIEW_DISTANCE = 10;
    public static inline var MAX_PIXELS = 10;

    public function new (data :LevelData)
    {
        _data = data;
    }

    override public function onAdded ()
    {
        _pixels = [];
        for (ii in 0...MAX_PIXELS) {
            var pixel = new PixelDisplay();
            _pixels.push(pixel);
            owner.addChild(pixel.entity);
        }
    }

    override public function onRemoved ()
    {
        // TODO
    }

    override public function onUpdate (dt :Float)
    {
        _data.player.x = System.pointer.x/20;
        _data.player.y = System.pointer.y/20;

        var snapshot = createSnapshot();

        var ii = 0, ll = MAX_PIXELS;
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
    }

    private function createSnapshot () :Array<PixelPriority>
    {
        var eyeX = _data.player.x;
        var eyeY = _data.player.y;

        var list = [];
        for (y in 0..._data.height) {
            for (x in 0..._data.width) {
                var priority = _data.getTerrainPriority(x, y);

                var dx = eyeX - x;
                var dy = eyeY - y;
                var distance = Math.sqrt(dx*dx + dy*dy);
                priority *= 5*Math.max(0, VIEW_DISTANCE-distance);

                if (priority > 0) {
                    var idx = findInsertIdx(list, priority);
                    if (idx < MAX_PIXELS) {
                        list.insert(idx, new PixelPriority(Terrain(x, y), priority));
                        if (list.length > MAX_PIXELS) {
                            list.splice(-1, 1); // Trim the excess
                        }
                    }
                }
            }
        }

        for (mob in _data.mobs) {
            var priority = LevelData.toPriority(mob.type);
            var dx = eyeX - mob.x;
            var dy = eyeY - mob.y;
            var distance = Math.sqrt(dx*dx + dy*dy);
            priority *= 5*Math.max(0, VIEW_DISTANCE-distance);

            if (priority > 0) {
                var idx = findInsertIdx(list, priority);
                if (idx < MAX_PIXELS) {
                    list.insert(idx, new PixelPriority(Mob(mob), priority));
                    if (list.length > MAX_PIXELS) {
                        list.splice(-1, 1); // Trim the excess
                    }
                }
            }
        }

        return list;
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

    private var _data :LevelData;
    private var _pixels :Array<PixelDisplay>;
}

private enum PixelType
{
    Terrain (x :Float, y :Float);
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

    public function new ()
    {
        sprite = new FillSprite(0x000000, SCALE, SCALE);
        entity = new Entity().add(sprite);
        set_type(null);
    }

    private function get_type () return _type;
    private function set_type (type :PixelType) :PixelType
    {
        if (type != null) {
            sprite.visible = true;
            switch (type) {
            case Terrain(x, y):
                sprite.color = 0x000000;
                sprite.setXY(x*SCALE, y*SCALE);
            case Mob(mob):
                sprite.color = 0xff0000;
                sprite.setXY(mob.x*SCALE - 0.5*SCALE, mob.y*SCALE - 0.5*SCALE);
            }
        } else {
            sprite.visible = false;
        }
        return _type = type;
    }

    private var _type :PixelType;
}
