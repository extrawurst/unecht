module unecht.core.components.physics.material;

import derelict.ode.ode;
import derelict.util.system;

import unecht.core.component;
import unecht.core.object;

import gl3n.linalg;

//TODO: support POD types in default inspectors automatically
///
struct UEPhysicsMaterialInfo
{
    dReal bouncyness = 0;
    dReal friction = dInfinity;

    @nogc @property bool isBouncy() const nothrow { return bouncyness > 0.01f; }
}

version(UEIncludeEditor)
{
    import unecht.core.componentManager;
    @EditorInspector("UEPhysicsMaterial")
    static class UEPhysicsMaterialInspector : IComponentEditor
    {
        override bool render(UEObject _component)
        {
            import derelict.imgui.imgui;
            import unecht.core.components.internal.gui;
            import std.format;
            
            auto thisT = cast(UEPhysicsMaterial)_component;
            
            UEGui.DragFloat("friction",thisT.materialInfo.friction,0,dInfinity);
            UEGui.DragFloat("bouncyness",thisT.materialInfo.bouncyness,0,1);

            //TODO: impl
            return false;
        }
        
        mixin UERegisterInspector!UEPhysicsMaterialInspector;
    }
}

///
final class UEPhysicsMaterial : UEComponent
{
    mixin(UERegisterObject!());

    @Serialize
    UEPhysicsMaterialInfo materialInfo;
}