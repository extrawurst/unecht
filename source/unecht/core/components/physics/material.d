module unecht.core.components.physics.material;

import derelict.ode.ode;
import derelict.util.system;

import unecht.core.component;
import unecht.core.object;
import unecht.core.defaultInspector;

import gl3n.linalg;

//TODO: support POD types in default inspectors automatically
///
struct UEPhysicsMaterialInfo
{
    @UEInspectorRange!float(0.0f,1.0f)
    dReal bouncyness = 0;
    @UEInspectorRange!float(0.0f,float.infinity)
    dReal friction = dInfinity;

    @nogc @property bool isBouncy() const nothrow { return bouncyness > 0.01f; }
}

///
final class UEPhysicsMaterial : UEComponent
{
    mixin(UERegisterObject!());

    @Serialize
    UEPhysicsMaterialInfo materialInfo;
}