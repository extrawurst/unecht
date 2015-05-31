module ball;

import unecht;

import app;

///
final class BallLogic : UEComponent
{
    mixin(UERegisterObject!());

    TestControls controls;

    override void onCreate() {
        super.onCreate;
        
        auto shape = entity.addComponent!UEShapeSphere;
        _physicsBody = entity.addComponent!UEPhysicsBody;
        _physicsBody.setDamping(0);
        entity.addComponent!UEPhysicsColliderSphere;
        
        auto sharedMaterial = entity.addComponent!UEMaterial;
        sharedMaterial.setProgram(UEMaterial.vs_shaded,UEMaterial.fs_shaded,"shaded");
        sharedMaterial.uniforms.setColor(vec4(1,0,0,1));

        shape.renderer.material = sharedMaterial;
        
        auto material = entity.addComponent!UEPhysicsMaterial;
        material.materialInfo.bouncyness = 1.0f;
        material.materialInfo.friction = 0;
        
        reset();
    }
    
    override void onCollision(UEComponent _collider) {
        if(_collider && _collider.entity.name == "border-out")
        {
            controls.onBallOut(_collider.entity);
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