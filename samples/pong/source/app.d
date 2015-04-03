module app;

import unecht;

///
final class PaddleLogic : UEComponent
{
    mixin(UERegisterComponent!());

    auto keyUp = UEKey.u;
    auto keyDown = UEKey.j;

    static border = 7.2f;

    static UEMaterial sharedMaterial;
    
    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);

        auto shape = entity.addComponent!UEShapeBox;
        entity.addComponent!UEPhysicsColliderBox;

        if(!sharedMaterial)
        {
            sharedMaterial = entity.addComponent!UEMaterial;
            sharedMaterial.setProgram(UEMaterial.vs_flat,UEMaterial.fs_flat,"flat");
            sharedMaterial.uniforms.setColor(vec4(0,1,0,1));
        }
        shape.renderer.material = sharedMaterial;

        auto material = entity.addComponent!UEPhysicsMaterial;
        material.materialInfo.bouncyness = 1.0f;
        material.materialInfo.friction = 0;
    }

    override void onUpdate() {
        super.onUpdate;

        auto pos = sceneNode.position;
        pos.z += 0.3f * control;
        pos.z = pos.z.clamp(-border,border);

        sceneNode.position = pos;
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

    static UEMaterial sharedMaterial;

    override void onCreate() {
        super.onCreate;

        auto shape = entity.addComponent!UEShapeSphere;
        _physicsBody = entity.addComponent!UEPhysicsBody;
        _physicsBody.setDamping(0);
        entity.addComponent!UEPhysicsColliderSphere;

        if(!sharedMaterial)
        {
            sharedMaterial = entity.addComponent!UEMaterial;
            sharedMaterial.setProgram(UEMaterial.vs_shaded,UEMaterial.fs_shaded,"shaded");
            sharedMaterial.uniforms.setColor(vec4(1,0,0,1));
        }
        shape.renderer.material = sharedMaterial;

        auto material = entity.addComponent!UEPhysicsMaterial;
        material.materialInfo.bouncyness = 1.0f;
        material.materialInfo.friction = 0;

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

        newE.addComponent!BallLogic;
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

///
final class GameBorders : UEComponent
{
    mixin(UERegisterComponent!());

    static immutable x = 15;
    static immutable z = 10;
    static immutable h = 2;
    
    override void onCreate() {
        super.onCreate;


        createBorder(false, vec3(0,h/2,-z), vec3(x,h,1));
        createBorder(false, vec3(0,h/2,z), vec3(x,h,1));
        createBorder(true, vec3(-x-1.1f,h/2,0), vec3(1,h,z));
        createBorder(true, vec3(x+1.1f,h/2,0), vec3(1,h,z));
    }

    void createBorder(bool _outside, vec3 _pos, vec3 _size)
    {
        auto name = "border";
        if(_outside)
            name ~="-out";

        auto newE = UEEntity.create(name,sceneNode);
        newE.sceneNode.position = _pos;
        newE.sceneNode.scaling = _size;
        auto shape = newE.addComponent!UEShapeBox;
        newE.addComponent!UEPhysicsColliderBox;
        if(!_outside)
        {
            shape.renderer.material.uniforms.setColor(vec4(0,1,0,1));

            auto material = newE.addComponent!UEPhysicsMaterial;
            material.materialInfo.bouncyness = 1.0f;
            material.materialInfo.friction = 0;
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