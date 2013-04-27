package blocky;

import flambe.asset.AssetPack;
import flambe.asset.Manifest;
import flambe.display.FillSprite;
import flambe.display.ImageSprite;
import flambe.display.Sprite;
import flambe.Entity;
import flambe.System;

class BlockyMain
{
    private static function main ()
    {
        System.init();

        System.root.addChild(new Entity()
            .add(new FillSprite(0xf0f0f0, System.stage.width, System.stage.height)));

        var loader = System.loadAssetPack(Manifest.build("bootstrap"));
        loader.get(onLoad);
    }

    private static function onLoad (pack :AssetPack)
    {
        var level = new LevelData(pack, "level1.txt", 20, 7);
        System.root.add(new LevelDisplay(level));
    }
}
