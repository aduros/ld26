package blocky;

import flambe.asset.AssetPack;
import flambe.util.Arrays;
import flambe.util.Assert;
import flambe.util.Signal1;
import flambe.util.Value;

using Lambda;
using StringTools;

enum BlockType
{
    Space; Wall;
    Lava; Goomba; Coin;

    Player;
}

class Mob
{
    public var type (default, null) :BlockType;

    public var x :Float;
    public var y :Float;
    public var velX :Float = 0;
    public var velY :Float = 0;
    public var grounded :Bool = false;

    public function new (type :BlockType, x :Float, y :Float)
    {
        this.type = type;
        this.x = x;
        this.y = y;
    }
}

class LevelData
{
    public static var GRAVITY = 10;
    public static var TERMINAL_VELOCITY = 20;

    public var width (default, null) :Int = 0;
    public var height (default, null) :Int = 0;

    public var terrain (default, null) :Array<BlockType>;
    public var terrainPriority (default, null) :Array<Float>;
    public var mobs (default, null) :Array<Mob>;

    public var player (default, null) :Mob;
    public var playerAlive (default, null) :Value<Bool>;
    public var playerCoined (default, null) :Signal1<Mob>;

    public function new (gameCtx :GameContext, name :String)
    {
        _gameCtx = gameCtx;
        terrain = [];
        mobs = [];

        var x = 0, y = 0;
        var str = gameCtx.pack.getFile(name);
        var ii = 0, ll = str.length;
        while (ii < ll) {
            var code = str.fastCodeAt(ii++);
            if (code != "\n".code) {
                var block = toBlockType(code);
                switch (block) {
                    case Wall, Space:
                    default:
                        var tileId = y*width + x;
                        if (block != Coin || !gameCtx.earnedCoins.has(tileId)) {
                            var mob = addMobile(block, x+0.5, y+0.5);
                            if (block == Player) {
                                player = mob;
                            }
                        }
                        block = Space;
                }
                terrain.push(block);

                ++x;
            } else {
                width = x;
                x = 0;
                ++y;
            }
        }
        height = y;

        var ADJACENCY_PRIORITY = 0.25;
        terrainPriority = [];
        for (y in 0...height) {
            for (x in 0...width) {
                var priority = toPriority(getTerrain(x, y));
                if (x > 0) priority *= 1 - ADJACENCY_PRIORITY*toPriority(getTerrain(x-1, y));
                if (x < width-1) priority *= 1 - ADJACENCY_PRIORITY*toPriority(getTerrain(x+1, y));
                if (y > 0) priority *= 1 - ADJACENCY_PRIORITY*toPriority(getTerrain(x, y-1));
                if (y < height-1) priority *= 1 - ADJACENCY_PRIORITY*toPriority(getTerrain(x, y+1));
                terrainPriority[width*y + x] = priority;
            }
        }

        playerAlive = new Value<Bool>(true);
        playerCoined = new Signal1();
    }

    public function update (dt :Float)
    {
        if (_paused) {
            return;
        }

        for (mob in mobs) {
            if (mob.velX != 0) {
                mob.x += dt*mob.velX;
                if (mob.velX < 0) {
                    checkLeftCollision(mob);
                } else if (mob.velX > 0) {
                    checkRightCollision(mob);
                }
            }
            mob.y += dt*mob.velY;
            if (mob.velY < 0) {
                checkTopCollision(mob);
                mob.grounded = false;
            } else {
                checkBottomCollision(mob);
            }

            if (mob != player) {
                var dx = player.x-mob.x, dy = player.y-mob.y;
                var sqrDist = dx*dx + dy*dy;
                if (sqrDist < 1) {
                    onPlayerTouched(mob);
                }
            }

            if (mob.type != Coin && mob.type != Lava) {
                mob.velY += dt*GRAVITY;
                if (mob.velY > TERMINAL_VELOCITY) {
                    mob.velY = TERMINAL_VELOCITY;
                }
            }
        }
    }

    private function onPlayerTouched (mob :Mob)
    {
        switch (mob.type) {
            case Lava, Goomba:
                _paused = true;
                playerAlive._ = false;
            case Coin:
                _paused = true;
                var coinId = Std.int(mob.y)*width + Std.int(mob.x);
                _gameCtx.earnedCoins.push(coinId);
                playerCoined.emit(mob);
            default:
        }
    }

    private function checkLeftCollision (mob :Mob)
    {
        var left = Math.ceil(mob.x-0.5) - 1;
        var right = Math.floor(mob.x+0.5);
        var top = Math.ceil(mob.y-0.5) - 1;
        var bottom = Math.floor(mob.y+0.5);
        if (collision(left, top+1) || collision(left, bottom-1)) {
            mob.x = left + 1.5;

            switch (mob.type) {
                case Goomba: mob.velX *= -1;
                default:
            }
        }
    }

    private function checkRightCollision (mob :Mob)
    {
        var right = Math.floor(mob.x+0.5);
        var top = Math.ceil(mob.y-0.5) - 1;
        var bottom = Math.floor(mob.y+0.5);
        if (collision(right, top+1) || collision(right, bottom-1)) {
            mob.x = right - 0.5;

            switch (mob.type) {
                case Goomba: mob.velX *= -1;
                default:
            }
        }
    }

    private function checkTopCollision (mob :Mob)
    {
        var left = Math.ceil(mob.x-0.5) - 1;
        var right = Math.floor(mob.x+0.5);
        var top = Math.ceil(mob.y-0.5) - 1;
        if (collision(left+1, top) || collision(right-1, top)) {
            mob.y = top + 1.5;
            mob.velY = 0;
        }
    }

    private function checkBottomCollision (mob :Mob)
    {
        var left = Math.ceil(mob.x-0.5) - 1;
        var right = Math.floor(mob.x+0.5);
        var bottom = Math.floor(mob.y+0.5);
        if (collision(left+1, bottom) || collision(right-1, bottom)) {
            mob.y = bottom - 0.5;
            mob.velY = 0;
            mob.grounded = true;
        } else {
            mob.grounded = false;
        }
    }

    private function collision (x :Int, y :Int) :Bool
    {
        return x < 0 || x >= width || y < 0 || y >= height || getTerrain(x, y) != Space;
    }

    inline public function getTerrain (x :Int, y :Int) :BlockType
    {
        return terrain[width*y + x];
    }

    inline public function getTerrainPriority (x :Int, y :Int) :Float
    {
        return terrainPriority[width*y + x];
    }

    public function addMobile (type :BlockType, x :Float, y :Float)
    {
        var mob = new Mob(type, x, y);
        switch(mob.type) {
        case Goomba:
            mob.velX = -3;
        default:
        }
        mobs.push(mob);
        return mob;
    }

    public function jump ()
    {
        if (player.grounded) {
            player.velY = -(4 + 0.6*_gameCtx.earnedCoins.length);
        }
    }

    public static function toPriority (block :BlockType) :Float
    {
        switch (block) {
            case Space: return 0;
            case Wall: return 1;
            case Player: return 1000;
            case Lava: return 1;
            case Goomba, Coin: return 2;
        }
    }

    private static function toBlockType (code :Int) :BlockType
    {
        switch (code) {
            case ".".code: return Space;
            case "X".code: return Wall;
            case "@".code: return Player;
            case "~".code: return Lava;
            case "2".code: return Goomba;
            case "$".code: return Coin;
        }
        Assert.fail("Unrecognized block", ["code", code]);
        return null;
    }

    private var _gameCtx :GameContext;
    private var _paused :Bool = false;
}
