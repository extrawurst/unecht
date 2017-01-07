module app;

import unecht;

///
@UEDefaultInspector!TestLogic
final class TestLogic : UEComponent
{
    mixin(UERegisterObject!());

    @Serialize
    private UEEntity ballRoot;

    @UEInspectorTooltip("try me")
    bool editable;

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);
        registerEvent(UEEventType.joystickStatus, &OnJoystick);
        registerEvent(UEEventType.joystickButton, &OnJoystick);
        registerEvent(UEEventType.joystickAxes, &OnJoystick);

        if(!ballRoot)
        {
            ballRoot = UEEntity.create("balls");

            spawnBall();
        }
    }

    override void onUpdate() {
        super.onUpdate;

        if(editable)
            spawnBall();

        editable = false;
    }

    void OnJoystick(UEEvent _ev)
    {
        import unecht.core.logger;
        if(_ev.eventType == UEEventType.joystickStatus)
            log.infof("joystatus: %s",_ev.joystickStatus);
        if(_ev.eventType == UEEventType.joystickButton)
            log.infof("joybutton: %s",_ev.joystickButton);
        if(_ev.eventType == UEEventType.joystickAxes)
            log.infof("joyaxes: %s",_ev.joystickAxes);
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();

            if(_ev.keyEvent.key == UEKey.num1)
                spawnBall();
            if(_ev.keyEvent.key == UEKey.num2)
                removeBall();
        }
    }

    void removeBall()
    {
        import std.random;
        auto rnd = uniform(0,ballRoot.sceneNode.children.length);

        UEEntity.destroy(ballRoot.sceneNode.children[rnd].entity);
    }

    void spawnBall()
    {
        auto newE = UEEntity.create("ball",ballRoot.sceneNode);

        {
            import std.random:uniform;
            newE.sceneNode.position = vec3(uniform(0.0f,2),15,uniform(0.0f,2));
        }

        newE.addComponent!UEPhysicsBody;
        newE.addComponent!UEPhysicsColliderBox;
        newE.addComponent!UEPhysicsMaterial;

        auto material = newE.addComponent!UEMaterial;
        material.setProgram(UEMaterial.vs_tex,UEMaterial.fs_tex, "tex");

        auto shape = newE.addComponent!UEShapeBox;

        ue.application.openSteamOverlay();
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