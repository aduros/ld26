package blocky;

import flambe.Entity;
import flambe.System;
import flambe.display.TextSprite;
import flambe.scene.Director;
import flambe.script.*;

class TextScene
{
    public static function show (gameCtx :GameContext, title :String, subtitle :String) :Entity
    {
        var scene = new Entity();
        var stageW = System.stage.width;

        var titleLabel = new TextSprite(gameCtx.titleFont, title);
        titleLabel.wrapWidth._ = stageW;
        titleLabel.align = Center;
        titleLabel.y._ = 100;
        titleLabel.alpha._ = 0;
        scene.addChild(new Entity().add(titleLabel));

        var subtitleLabel = new TextSprite(gameCtx.infoFont, subtitle);
        subtitleLabel.wrapWidth._ = stageW;
        subtitleLabel.align = Center;
        subtitleLabel.y._ = 300;
        subtitleLabel.alpha._ = 0;
        scene.addChild(new Entity().add(subtitleLabel));

        var script = new Script();
        script.run(new Sequence([
            new AnimateTo(titleLabel.alpha, 1, 1),
            new Delay(0.5),
            new AnimateTo(subtitleLabel.alpha, 1, 1),
        ]));

        gameCtx.root.get(Director).unwindToScene(scene);
        return scene.add(script);
    }
}
