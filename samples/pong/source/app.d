module app;

import unecht;

import ball;
import paddle;
import field;

import derelict.imgui.imgui;

///
@UEDefaultInspector!TestControls
final class TestControls : UEComponent
{
    mixin(UERegisterComponent!());

    static UEEntity balls;
    static int ballCount;

    Field field;

    float lastBallCreated;

    int scoreLeft;
    int scoreRight;

    override void onCreate() {
        super.onCreate;

        field = entity.addComponent!Field;

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

        ig_PushStyleColor(ImGuiCol_WindowBg, ImVec4(1,1,1,0));
        auto labelWidth = 100;
        ig_SetNextWindowPos(ImVec2((ue.application.mainWindow.size.width-labelWidth)/2));
        ig_SetNextWindowSize(ImVec2(labelWidth,-1),ImGuiSetCond_Once);
        ig_Begin("",null,ImGuiWindowFlags_NoMove|ImGuiWindowFlags_NoTitleBar|ImGuiWindowFlags_NoResize);
        UEGui.Text(.format("%s - %s",scoreLeft,scoreRight));
        ig_End();
        ig_PopStyleColor();
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
        auto ballLogic = newE.addComponent!BallLogic;
        ballLogic.controls = this;

        lastBallCreated = ue.tickTime;
        ballCount++;
    }

    void onBallOut(UEEntity border)
    {
        if(field.isLeft(border))
            scoreRight++;
        else
            scoreLeft++;
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
            paddleLogic.joystickId = 1;
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

        import unecht.core.components.camera;
		auto newE2 = UEEntity.create("camera entity");
		newE2.sceneNode.position = vec3(0,30,0);
        newE2.sceneNode.angles = vec3(90,0,0);
		auto cam = newE2.addComponent!UECamera;
        cam.isOrthographic = true;
        cam.orthoSize = 30.0f;
	};
}