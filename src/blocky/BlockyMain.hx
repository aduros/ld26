package blocky;

import flambe.asset.AssetEntry;
import flambe.asset.AssetPack;
import flambe.asset.Manifest;
import flambe.input.TouchPoint;
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
    }
}
