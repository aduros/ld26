package blocky;

import flambe.Entity;
import flambe.asset.AssetPack;
import flambe.display.Font;
import flambe.scene.Director;

class GameContext
{
    public var pack (default, null) :AssetPack;
    public var earnedCoins (default, null) :Array<Int>;
    public var maxPixels :Int = 13;

    public var root :Entity;

    public var titleFont :Font;
    public var infoFont :Font;

    public function new (pack :AssetPack, root :Entity)
    {
        this.pack = pack;
        this.root = root;
        earnedCoins = [];
        titleFont = new Font(pack, "title");
        infoFont = new Font(pack, "info");

        if (!root.has(Director)) {
            root.add(new Director());
        }
    }
}
