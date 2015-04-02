module unecht.core.components.physics.dynamic;

import derelict.ode.ode;
import derelict.util.system;

import unecht.core.component;
import unecht.core.components.physics.system;

import gl3n.linalg;

///
final class UEPhysicsBody : UEComponent 
{
    mixin(UERegisterComponent!());
    
    void addForce(vec3 _v)
    {
        dBodyAddForce(Body, _v.x, _v.y, _v.z);
    }
    
    void setDamping(float _v)
    {
        dBodySetLinearDamping(Body, _v);
    }
    
    vec3 getVelocity() {
        auto vel = dBodyGetLinearVel(Body);
        return vec3(vel[0..2]);
    }
    
    void setVelocity(vec3 _v) {
        dBodySetLinearVel(Body, _v.x,_v.y,_v.z);
    }
    
    override void onCreate() {
        super.onCreate;
        
        // This brings us to the end of the world settings, now we have to initialize the objects themselves.
        // Create a new body for our object in the world and get its ID.
        Body = dBodyCreate(UEPhysicsSystem.world);
        
        auto pos = sceneNode.position;
        dBodySetPosition(Body, pos.x, pos.y, pos.z);
        auto rot = sceneNode.rotation;
        dBodySetQuaternion(Body, rot.quaternion);
        
        // Here I have set the initial linear velocity to stationary and let gravity do the work, but you can experiment
        // with the velocity vector to change the starting behaviour. You can also set the rotational velocity for the new
        // body using dBodySetAngularVel which takes the same parameters.
        dBodySetLinearVel(Body, 0,0,0);
        
        dBodySetData(Body, cast(void*)this);
        
        // Now we need to create a box mass to go with our geom. First we create a new dMass structure (the internals
        // of which aren't important at the moment) then create an array of 3 float (dReal) values and set them
        // to the side lengths of our box along the x, y and z axes. We then pass the both of these to dMassSetBox with a
        // pre-defined DENSITY value of 0.5 in this case.
        dMass m;
        
        dReal[3] sides;
        sides[0] = 2.0;
        sides[1] = 2.0;
        sides[2] = 2.0;
        static immutable DENSITY = 1.0f;
        dMassSetBox(&m, DENSITY, sides[0], sides[1], sides[2]);
        
        // We can then apply this mass to our objects body.
        dBodySetMass(Body, &m);
    }
    
    ///
    override void onUpdate() {
        if(lastPos != sceneNode.position)
            dBodySetPosition(Body, sceneNode.position.x,sceneNode.position.y,sceneNode.position.z);
        
        if(lastRot != sceneNode.rotation)
            dBodySetQuaternion(Body, sceneNode.rotation.quaternion);
        
        auto pos = dBodyGetPosition(Body);
        auto qrot = dBodyGetQuaternion(Body);
        
        quat rot = quat(qrot[0],qrot[1],qrot[2],qrot[3]);
        
        this.sceneNode.position = lastPos = vec3(pos[0..3]);
        this.sceneNode.rotation = lastRot = rot;
    }
    
private:
    vec3 lastPos;
    quat lastRot;
    
    package dBodyID Body;  // the dynamics body
}