package blocky;

import flambe.Component;
import flambe.Disposer;
import flambe.Entity;
import flambe.System;
import flambe.animation.AnimatedFloat;
import flambe.display.FillSprite;
import flambe.display.Sprite;
import flambe.math.FMath;
import flambe.util.Assert;
import flambe.util.Signal1;
import flambe.script.*;

import blocky.LevelData;

class LevelDisplay extends Component
{
    public static inline var VIEW_DISTANCE = 10;

    public var gameOver (default, null) :Signal1<Bool>;

    public function new (gameCtx :GameContext, data :LevelData, showIntro :Bool)
    {
        _gameCtx = gameCtx;
        _level = data;
        _showIntro = showIntro;
        _pixelCount = new AnimatedFloat(0);
        gameOver = new Signal1();
    }

    override public function onAdded ()
    {
        var worldEntity = new Entity().add(_world = new Sprite());
        owner.addChild(worldEntity);

        _pixels = [];
        for (ii in 0..._gameCtx.maxPixels) {
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

        var script = new Script();
        owner.add(script);

        _level.playerAlive.changed.connect(function (alive,_) {
            if (!alive) {
                script.run(new Sequence([
                    new Parallel([
                        new AnimateTo(_world.alpha, 0, 0.5),
                        new AnimateTo(_pixelCount, 0, 0.5),
                    ]),
                    new CallFunction(function () gameOver.emit(false)),
                ]));
            }
        });

        _level.playerCoined.connect(function (coin) {
            script.run(new Sequence([
                new Parallel([
                    new AnimateTo(_world.alpha, 0, 0.5),
                    new AnimateTo(_pixelCount, 0, 0.5),
                ]),
                new CallFunction(function () gameOver.emit(true)),
            ]));
        }).once();

        // onUpdate(0);
        // script.run(new Sequence([
        // ]));

        _pixelCount._ = _gameCtx.maxPixels;

        if (_showIntro) {
            var ii = 0, ll = _pixels.length;
            while (ii < ll) {
                var pixel = _pixels[ii];
                pixel.sprite.color = 0;
                pixel.sprite.visible = true;
                pixel.sprite.setXY(ii*(PixelDisplay.SCALE+5) + 10, 10);
                ++ii;
            }

            var hudCoins = [];
            for (ii in 0..._gameCtx.earnedCoins.length) {
                var coin = new Entity()
                    .add(new FillSprite(0xffcc00, PixelDisplay.SCALE, PixelDisplay.SCALE)
                        .setXY(ii*(PixelDisplay.SCALE+5) + 10, PixelDisplay.SCALE+20));
                worldEntity.addChild(coin);
                hudCoins.push(coin);
            }

            _paused = true;
            script.run(new Sequence([
                new Delay(2),
                new CallFunction(function () {
                    for (coin in hudCoins) {
                        coin.dispose();
                    }
                    _paused = false; // HACK
                    onUpdate(0);
                    _paused = true;
                    var ii = 0, ll = _pixels.length;
                    while (ii < ll) {
                        var pixel = _pixels[ii++];
                        pixel.sprite.x.animate(ii * PixelDisplay.SCALE + 5, pixel.sprite.x._, 0.5);
                        pixel.sprite.y.animate(5, pixel.sprite.y._, 0.5);
                    }
                }),
                new Delay(0.5),
                new CallFunction(function () {
                    _paused = false;
                }),
            ]));
        } else {
            _world.alpha.animate(0.25, 1, 1);
            _pixelCount.animateTo(_gameCtx.maxPixels, 1);
        }

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
        if (_paused) {
            return;
        }

        _pixelCount.update(dt);

        if (System.keyboard.isDown(Left)) {
            _level.player.velX = -5;
        } else if (System.keyboard.isDown(Right)) {
            _level.player.velX = 5;
        } else {
            _level.player.velX *= 0.9;
        }
        _level.update(dt);

        var snapshot = createSnapshot(Std.int(_pixelCount._));

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

        var ii = 0, ll = _pixels.length;
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

    private function createSnapshot (size :Int) :Array<PixelPriority>
    {
        var eyeX = _level.player.x;
        var eyeY = _level.player.y;

        var list = [];
        var startX = FMath.max(0, Std.int(eyeX-VIEW_DISTANCE/2));
        var startY = FMath.max(0, Std.int(eyeY-VIEW_DISTANCE/2));
        var endX = FMath.min(_level.width, startX+VIEW_DISTANCE);
        var endY = FMath.min(_level.height, startY+VIEW_DISTANCE);

        for (y in startY...endY) {
            for (x in startX...endX) {
                var priority = _level.getTerrainPriority(x, y);

                var dx = eyeX - x;
                var dy = eyeY - y;
                var distance = Math.sqrt(dx*dx + dy*dy);
                priority *= 5*Math.max(0, VIEW_DISTANCE-distance);

                if (priority > 0) {
                    var idx = findInsertIdx(list, priority);
                    if (idx < size) {
                        list.insert(idx, new PixelPriority(Terrain(x, y), priority));
                        if (list.length > size) {
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
                if (idx < size) {
                    list.insert(idx, new PixelPriority(Mob(mob), priority));
                    if (list.length > size) {
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

    private var _gameCtx :GameContext;
    private var _level :LevelData;
    private var _showIntro :Bool;

    private var _world :Sprite;
    private var _pixels :Array<PixelDisplay>;
    private var _pixelCount :AnimatedFloat;
    private var _paused = false;
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
            case Lava: return 0xff0000;
            case Goomba: return 0x009900;
            case Player: return 0x000099;
            case Coin: return 0xffcc00;
        }
    }

    private var _type :PixelType;
    private var _level :LevelData;
}
