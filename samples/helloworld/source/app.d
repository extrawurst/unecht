module app;

import unecht;

///
final class PaddleLogic : UEComponent
{
    mixin(UERegisterComponent!());

    auto keyUp = UEKey.u;
    auto keyDown = UEKey.j;
    
    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);
    }

    override void onUpdate() {
        super.onUpdate;

        sceneNode.position = sceneNode.position + (vec3(0,0,0.3f)*control);
    }

    private void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down ||
            _ev.keyEvent.action == UEEvent.KeyEvent.Action.Up
            )
        {
            bool pressed = _ev.keyEvent.action == UEEvent.KeyEvent.Action.Down;

            if(_ev.keyEvent.key == keyUp)
            {
                control += pressed?1:-1;
            }
            else if(_ev.keyEvent.key == keyDown)
            {
                control -= pressed?1:-1;
            }
        }
    }
    
private:
    float control = 0;
}

///
final class BallLogic : UEComponent
{
    mixin(UERegisterComponent!());

    override void onCreate() {
        super.onCreate;

        _physicsBody = entity.getComponent!UEPhysicsBody;

        _physicsBody.setDamping(0);

        reset();
    }

    override void onCollision(UEComponent _collider) {
        if(_collider && _collider.entity.name == "border-out")
        {
            reset();
        }
    }

    private void reset()
    {
        import std.random;
        sceneNode.position = vec3(0,sceneNode.position.y,0);
        _physicsBody.setVelocity(vec3(uniform(-5,5),0,uniform(-5,5)));
    }

private:
    UEPhysicsBody _physicsBody;
}

///
final class TestControls : UEComponent
{
    mixin(UERegisterComponent!());

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);

        spawnBall();
        spawnPaddle(false);
        spawnPaddle(true);
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();

            if(_ev.keyEvent.key == UEKey.num2)
            {
                spawnBall();
            }
        }
    }

    static void spawnBall()
    {
        auto newE = UEEntity.create("ball");
        import std.random:uniform;
        newE.sceneNode.position = vec3(uniform(0.0f,1),1,uniform(0.0f,1));

        newE.addComponent!UEShapeSphere;
        newE.addComponent!UEPhysicsBody;
        newE.addComponent!UEPhysicsColliderSphere;
        newE.addComponent!BallLogic;
    }

    static void spawnPaddle(bool rightSide)
    {
        float side = rightSide?1:-1;

        auto newE = UEEntity.create("paddle");
        import std.random:uniform;
        newE.sceneNode.position = vec3(-14.5*side,1,0);
        newE.sceneNode.scaling = vec3(0.5,1,2);

        newE.addComponent!UEShapeBox;
        newE.addComponent!UEPhysicsColliderBox;
        auto paddleLogic = newE.addComponent!PaddleLogic;

        if(!rightSide)
        {
            paddleLogic.keyUp = UEKey.r;
            paddleLogic.keyDown = UEKey.f;
        }
    }
}

///
final class GameBorders : UEComponent
{
    mixin(UERegisterComponent!());

    static immutable x = 15;
    static immutable z = 10;
    static immutable h = 2;
    
    override void onCreate() {
        super.onCreate;

        {
            auto newE = UEEntity.create("border",sceneNode);
            newE.sceneNode.position = vec3(0,h/2,-z);
            newE.sceneNode.scaling = vec3(x,h,1);
            newE.addComponent!UEShapeBox;
            newE.addComponent!UEPhysicsColliderBox;
        }
        {
            auto newE = UEEntity.create("border",sceneNode);
            newE.sceneNode.position = vec3(0,h/2,z);
            newE.sceneNode.scaling = vec3(x,h,1);
            newE.addComponent!UEShapeBox;
            newE.addComponent!UEPhysicsColliderBox;
        }
        {
            auto newE = UEEntity.create("border-out",sceneNode);
            newE.sceneNode.position = vec3(-x-1.1f,h/2,0);
            newE.sceneNode.scaling = vec3(1,h,z);
            newE.addComponent!UEShapeBox;
            newE.addComponent!UEPhysicsColliderBox;
        }
        {
            auto newE = UEEntity.create("border-out",sceneNode);
            newE.sceneNode.position = vec3(x+1.1f,h/2,0);
            newE.sceneNode.scaling = vec3(1,h,z);
            newE.addComponent!UEShapeBox;
            newE.addComponent!UEPhysicsColliderBox;
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
        newE.addComponent!GameBorders;

        import unecht.core.components.camera;
		auto newE2 = UEEntity.create("camera entity");
		newE2.sceneNode.position = vec3(0,30,0);
		auto cam = newE2.addComponent!UECamera;
        cam.rotation = vec3(90,0,0);
        cam.isOrthographic = true;
        cam.orthoSize = 30.0f;
	};
}