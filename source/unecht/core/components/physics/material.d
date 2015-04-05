module unecht.core.components.physics.material;

import derelict.ode.ode;
import derelict.util.system;

import unecht.core.component;

import gl3n.linalg;

///
struct UEPhysicsMaterialInfo
{
    dReal bouncyness = 0;
    dReal friction = dInfinity;

    @nogc @property bool isBouncy() const nothrow { return bouncyness > 0.01f; }
}

///
final class UEPhysicsMaterial : UEComponent
{
    mixin(UERegisterComponent!());
    
    UEPhysicsMaterialInfo materialInfo;
}