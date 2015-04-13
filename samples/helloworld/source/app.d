module app;

import unecht;

///
final class TestLogic : UEComponent
{
    mixin(UERegisterComponent!());

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);

        //spawnBall();

        auto newE = UEEntity.create("box");
        newE.addComponent!UEShapeBox;
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();

            if(_ev.keyEvent.key == UEKey.num2)
                spawnBall();
        }
    }

    void spawnBall()
    {
        auto newE = UEEntity.create("obj");
        import std.random:uniform;
        newE.sceneNode.position = vec3(uniform(0.0f,2),15,uniform(0.0f,2));
        newE.addComponent!UEPhysicsBody;
        newE.addComponent!UEPhysicsColliderBox;
        newE.addComponent!UEShapeBox;
        newE.addComponent!UEPhysicsMaterial;
    }
}

shared static this()
{
	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - hello world sample";

	ue.hookStartup = () {
		auto newE = UEEntity.create("game");
        newE.addComponent!TestLogic;
        newE.addComponent!UEPhysicsColliderPlane;
        newE.addComponent!UEPhysicsMaterial;

		auto newE2 = UEEntity.create("camera entity");
		newE2.sceneNode.position = vec3(0,15,-20);
        newE2.sceneNode.angles = vec3(30,0,0);

        import unecht.core.components.camera;
		auto cam = newE2.addComponent!UECamera;
	};
}