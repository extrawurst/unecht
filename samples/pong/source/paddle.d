module paddle;

import unecht;

///
final class PaddleLogic : UEComponent
{
    mixin(UERegisterObject!());
    
    auto keyUp = UEKey.u;
    auto keyDown = UEKey.j;

    auto joystickId = 0;
    
    static immutable BORDER = 7.2f;

    override void onCreate() {
        super.onCreate;
        
        registerEvent(UEEventType.key, &OnKeyEvent);
        registerEvent(UEEventType.joystickAxes, &onJoystick);
        
        auto shape = entity.addComponent!UEShapeBox;
        entity.addComponent!UEPhysicsColliderBox;

        auto sharedMaterial = entity.getComponent!UEMaterial;
        sharedMaterial.setProgram(UEMaterial.vs_flat,UEMaterial.fs_flat,"flat");
        sharedMaterial.uniforms.setColor(vec4(0,1,0,1));
     
        import unecht.core.components.renderer;
        entity.getComponent!(UERenderer).material = sharedMaterial;
        
        auto material = entity.addComponent!UEPhysicsMaterial;
        material.materialInfo.bouncyness = 1.0f;
        material.materialInfo.friction = 0;
    }
    
    override void onUpdate() {
        super.onUpdate;
        
        auto pos = sceneNode.position;
        pos.z += 0.3f * control;
        pos.z = pos.z.clamp(-BORDER,BORDER);
        
        sceneNode.position = pos;
    }

    void onJoystick(UEEvent _ev)
    {
        if(_ev.joystickAxes.id == joystickId)
        {
            control = -_ev.joystickAxes.axes[1];
        }
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
