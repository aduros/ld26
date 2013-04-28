package blocky;

import flambe.asset.AssetPack;

class GameContext
{
    public var pack (default, null) :AssetPack;
    public var earnedCoins (default, null) :Array<Int>;
    public var maxPixels :Int = 14;

    public function new (pack :AssetPack)
    {
        this.pack = pack;
        this.earnedCoins = [];
    }
}
