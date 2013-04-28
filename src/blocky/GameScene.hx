package blocky;

import flambe.Entity;
import flambe.System;
import flambe.display.TextSprite;
import flambe.scene.Director;
import flambe.scene.FadeTransition;

class GameScene
{
    public static function show (gameCtx :GameContext) :Entity
    {
        var scene = new Entity();
        var level = new LevelData(gameCtx, "level1.txt");

        var display = new LevelDisplay(gameCtx, level);
        display.gameOver.connect(function (won) {
            if (won) {
                gameCtx.maxPixels -= 1;
            }
            if (gameCtx.earnedCoins.length >= 10) {
                TextScene.show(gameCtx, "You got all the coins!", "But now you can't see");
            } else {
                GameScene.show(gameCtx);
            }
        });
        scene.add(display);

        gameCtx.root.get(Director).unwindToScene(scene);
        return scene;
    }
}
