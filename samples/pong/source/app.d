module app;

import unecht;

import ball;
import paddle;
import field;

///
final class TestControls : UEComponent
{
    mixin(UERegisterComponent!());

    static UEEntity balls;
    static int ballCount;

    float lastBallCreated;

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);

        balls = UEEntity.create("balls");

        spawnBall();
        spawnPaddle(false);
        spawnPaddle(true);
    }

    override void onUpdate() {
        super.onUpdate;

        if(ue.tickTime - lastBallCreated > ballCount*2)
            spawnBall();
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();
        }
    }

    void spawnBall()
    {
        auto newE = UEEntity.create("ball",balls.sceneNode);
        import std.random:uniform;
        newE.sceneNode.position = vec3(uniform(0.0f,1),1,uniform(0.0f,1));
        newE.addComponent!BallLogic;

        lastBallCreated = ue.tickTime;
        ballCount++;
    }

    static void spawnPaddle(bool rightSide)
    {
        float side = rightSide?1:-1;

        auto newE = UEEntity.create("paddle");
        import std.random:uniform;
        newE.sceneNode.position = vec3(-14.5*side,1,0);
        newE.sceneNode.scaling = vec3(0.5,1,2);

        auto paddleLogic = newE.addComponent!PaddleLogic;

        if(!rightSide)
        {
            paddleLogic.keyUp = UEKey.r;
            paddleLogic.keyDown = UEKey.f;
        }
    }
}

shared static this()
{
	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - pong sample";

	ue.hookStartup = () {
        UEPhysicsSystem.setGravity(vec3(0));

		auto newE = UEEntity.create("game");
        newE.addComponent!TestControls;
        newE.addComponent!Field;

        import unecht.core.components.camera;
		auto newE2 = UEEntity.create("camera entity");
		newE2.sceneNode.position = vec3(0,30,0);
        newE2.sceneNode.angles = vec3(90,0,0);
		auto cam = newE2.addComponent!UECamera;
        cam.isOrthographic = true;
        cam.orthoSize = 30.0f;
	};
}