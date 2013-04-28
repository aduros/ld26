package blocky;

import flambe.asset.AssetPack;
import flambe.asset.Manifest;
import flambe.display.FillSprite;
import flambe.display.ImageSprite;
import flambe.display.Sprite;
import flambe.Entity;
import flambe.System;
import flambe.Disposer;

class BlockyMain
{
    private static function main ()
    {
        System.init();

        System.root.addChild(new Entity()
            .add(new FillSprite(0xf0f0f0, System.stage.width, System.stage.height)));

        var loader = System.loadAssetPack(Manifest.build("bootstrap"));
        loader.get(function (pack) {
            var gameCtx = new GameContext(pack, System.root);
            var introScene = TextScene.show(gameCtx, "There Are Only 13 Squares", "Arrow keys\nFind all 10 coins");
            var disposer = new Disposer();
            introScene.add(disposer); // FIXME(bruno): Disposer fails if added to component after setup!!
            disposer.connect1(System.keyboard.down, function (event) {
                switch (event.key) {
                case Up, Left, Down, Right:
                    GameScene.show(gameCtx);
                default:
                }
            });
        });
    }

    private static function restart (gameCtx :GameContext)
    {
        var level = new LevelData(gameCtx, "level1.txt");

        var game = new Entity();
        var display = new LevelDisplay(gameCtx, level);
        display.gameOver.connect(function (won) {
            game.dispose();
            if (won) {
                gameCtx.maxPixels -= 1;
            }
            restart(gameCtx);
        });
        game.add(display);

        System.root.addChild(game);
    }
}
