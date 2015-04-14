module unecht.core.components.physics.collider;

import derelict.ode.ode;
import derelict.util.system;

import unecht.core.component;
import unecht.core.components.physics.system;
import unecht.core.components.physics.dynamic;

import gl3n.linalg;

abstract class UEPhysicsGeometry : UEComponent
{
    mixin(UERegisterComponent!());

    protected dGeomID _geom;

    ///
    override void onDestroy() {
        super.onDestroy;

        if(_geom)
            dGeomDestroy(_geom);

        _geom = null;
    }
}

///
final class UEPhysicsColliderPlane : UEPhysicsGeometry
{
    mixin(UERegisterComponent!());
    
    override void onCreate() {
        super.onCreate;
        
        // Create a ground plane in our collision space by passing Space as the first argument to dCreatePlane.
        // The next four parameters are the planes normal (a, b, c) and distance (d) according to the plane
        // equation a*x+b*y+c*z=d and must have length 1
        _geom = dCreatePlane(UEPhysicsSystem.space, 0, 1, 0, 0);
    }
}

///
final class UEPhysicsColliderBox : UEPhysicsGeometry
{
    mixin(UERegisterComponent!());
    
    vec3 size = vec3(2);

    ///
    override void onCreate() {
        super.onCreate;
        
        _rigidBody = entity.getComponent!UEPhysicsBody;
        //TODO: logging
        
        // Here we create the actual geom object using dCreateBox. Note that this also adds the geom to our 
        // collision space and sets the size of the geom to that of our box mass.
        _geom = dCreateBox(UEPhysicsSystem.space, size.x*sceneNode.scaling.x, size.y*sceneNode.scaling.y, size.z*sceneNode.scaling.z);
        
        dGeomSetData(_geom, cast(void*)this);
        
        if(_rigidBody)
        {
            // And lastly we want to associate the body with the geom using dGeomSetBody. Setting a body on a geom automatically
            // combines the position vector and rotation matrix of the body and geom so that setting the position or orientation
            // of one will set the value for both objects. The ODE docs have a lot more to say about the geom functions.
            dGeomSetBody(_geom, _rigidBody.Body);
        }
        else
        {
            auto pos = _lastPos = this.sceneNode.position;
            dGeomSetPosition(_geom, pos.x, pos.y, pos.z);
        }
    }

    ///
    override void onUpdate() {
        if(!_rigidBody)
        {
            auto posNow = sceneNode.position;
            auto rotNow = sceneNode.rotation;
            if(_lastPos != posNow)
                dGeomSetPosition(_geom, posNow.x, posNow.y, posNow.z);
            if(_lastRot != rotNow)
                dGeomSetQuaternion(_geom, rotNow.quaternion);
            
            auto pos = dGeomGetPosition(_geom);
            float[4] qrot;
            dGeomGetQuaternion(_geom,qrot);
            
            quat rot = quat(qrot[0],qrot[1],qrot[2],qrot[3]);
            
            this.sceneNode.position = _lastPos = vec3(pos[0..3]);
            this.sceneNode.rotation = _lastRot = rot;
        }
    }
    
private:
    UEPhysicsBody _rigidBody;
    vec3 _lastPos;
    quat _lastRot;
}

///
final class UEPhysicsColliderSphere : UEPhysicsGeometry
{
    mixin(UERegisterComponent!());
    
    float rad=1.0f;
    
    override void onCreate() {
        super.onCreate;
        
        auto rigidBody = entity.getComponent!UEPhysicsBody;
        
        _geom = dCreateSphere(UEPhysicsSystem.space, rad);
        
        dGeomSetData(_geom, cast(void*)this);
        
        if(rigidBody)
            dGeomSetBody(_geom, rigidBody.Body);
    }
}
