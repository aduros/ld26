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
        loader.get(function (pack) {
            restart(new GameContext(pack), true);
        });
    }

    private static function restart (gameCtx :GameContext, showIntro :Bool)
    {
        var level = new LevelData(gameCtx, "level1.txt");

        var game = new Entity();
        var display = new LevelDisplay(gameCtx, level, showIntro);
        display.gameOver.connect(function (won) {
            game.dispose();
            if (won) {
                gameCtx.maxPixels -= 1;
            }
            restart(gameCtx, won);
        });
        game.add(display);

        System.root.addChild(game);
    }
}
