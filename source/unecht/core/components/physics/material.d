module unecht.core.components.physics.material;

import derelict.ode.ode;
import derelict.util.system;

import unecht.core.component;

import gl3n.linalg;

///
struct UEPhysicsMaterialInfo
{
    float bouncyness = 0;
    float friction = 0.6f;

    @nogc @property bool isBouncy() const nothrow { return bouncyness > 0.0f; }
}

///
final class UEPhysicsMaterial : UEComponent
{
    mixin(UERegisterComponent!());
    
    UEPhysicsMaterialInfo materialInfo;
}