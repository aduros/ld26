package blocky;

import flambe.asset.AssetPack;
import flambe.util.Arrays;
import flambe.util.Assert;

using StringTools;

enum BlockType
{
    Space; Wall;
    Monster;

    Player;
}

class Mob
{
    public var type (default, null) :BlockType;
    public var x :Float;
    public var y :Float;

    public function new (type :BlockType, x :Float, y :Float)
    {
        this.type = type;
        this.x = x;
        this.y = y;
    }
}

class LevelData
{
    public var width (default, null) :Int;
    public var height (default, null) :Int;

    public var terrain (default, null) :Array<BlockType>;
    public var terrainPriority (default, null) :Array<Float>;
    public var mobs (default, null) :Array<Mob>;

    public var player (default, null) :Mob;

    public function new (pack :AssetPack, name :String, width :Int, height :Int)
    {
        this.width = width;
        this.height = height;
        terrain = [];
        mobs = [];

        var x = 0, y = 0;
        var str = pack.getFile(name);
        var ii = 0, ll = str.length;
        while (ii < ll) {
            var code = str.fastCodeAt(ii++);
            if (code != "\n".code) {
                var block = toBlockType(code);
                switch (block) {
                    case Monster, Player:
                        var mob = addMobile(block, x+0.5, y+0.5);
                        if (block == Player) {
                            player = mob;
                        }
                        block = Space;
                    default:
                }
                terrain.push(block);

                ++x;
            } else {
                x = 0;
                ++y;
            }
        }

        var ADJACENCY_PRIORITY = -0.25;
        terrainPriority = [];
        for (y in 0...height) {
            for (x in 0...width) {
                var priority = toPriority(getTerrain(x, y));
                if (x > 0) priority += ADJACENCY_PRIORITY*toPriority(getTerrain(x-1, y));
                if (x < width-1) priority += ADJACENCY_PRIORITY*toPriority(getTerrain(x+1, y));
                if (y > 0) priority += ADJACENCY_PRIORITY*toPriority(getTerrain(x, y-1));
                if (y < height-1) priority += ADJACENCY_PRIORITY*toPriority(getTerrain(x, y+1));
                terrainPriority[width*y + x] = priority;
            }
        }
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
        mobs.push(mob);
        return mob;
    }

    public static function toPriority (block :BlockType) :Float
    {
        switch (block) {
            case Space: return 0;
            case Wall: return 1;
            case Player: return 1000;
            case Monster: return 10;
        }
    }

    private static function toBlockType (code :Int) :BlockType
    {
        switch (code) {
            case ".".code: return Space;
            case "X".code: return Wall;
            case "@".code: return Player;
            case "1".code: return Monster;
        }
        Assert.fail("Unrecognized block", ["code", code]);
        return null;
    }
}
