module app;

import unecht;

import ball;
import paddle;
import field;

import derelict.imgui.imgui;

///
final class TestControls : UEComponent
{
    mixin(UERegisterObject!());

    @Serialize
    UEEntity balls;
    @Serialize
    UEEntity paddles;
    @Serialize
    Field field;

    float lastBallCreated=0;

    int scoreLeft;
    int scoreRight;

    @property ulong ballCount() const {return balls.sceneNode.children.length;}

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);

        if(field is null)
            field = entity.addComponent!Field;

        if(balls is null)
            balls = UEEntity.create("balls");

        assert(balls);
        assert(balls.sceneNode);

        if(balls.sceneNode.children.length == 0)
            spawnBall();

        if(paddles is null)
        {
            paddles = UEEntity.create("paddles");

            spawnPaddle(false);
            spawnPaddle(true);
        }
    }

    override void onUpdate() {
        super.onUpdate;

        if(ue.tickTime - lastBallCreated > ballCount*2)
            spawnBall();

        igPushStyleColor(ImGuiCol_WindowBg, ImVec4(1,1,1,0));
        auto labelWidth = 100;
        igSetNextWindowPos(ImVec2((ue.application.mainWindow.size.width-labelWidth)/2));
        igSetNextWindowSize(ImVec2(labelWidth,-1),ImGuiSetCond_Once);
        igBegin("",null,ImGuiWindowFlags_NoMove|ImGuiWindowFlags_NoTitleBar|ImGuiWindowFlags_NoResize);
        UEGui.Text(.format("%s - %s",scoreLeft,scoreRight));
        igEnd();
        igPopStyleColor();
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
    }

    void onBallOut(UEEntity border)
    {
        if(field.isLeft(border))
            scoreRight++;
        else
            scoreLeft++;
    }

    void spawnPaddle(bool rightSide)
    {
        float side = rightSide?1:-1;

        auto newE = UEEntity.create("paddle",paddles.sceneNode);
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