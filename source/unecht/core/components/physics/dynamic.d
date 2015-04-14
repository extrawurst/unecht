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

    override void onDestroy() {
        super.onDestroy;

        //reactivate connected bodies
        auto n = dBodyGetNumJoints(Body);

        foreach(i; 0..n)
        {
            auto joint = dBodyGetJoint(Body, i);
            auto body0 = dJointGetBody(joint,0);
            auto body1 = dJointGetBody(joint,1);
            if(body0)
                dBodyEnable(body0);
            if(body1)
                dBodyEnable(body1);
        }

        dBodyDestroy(Body);
    }
    
    ///
    override void onUpdate() {
        auto doEnable = lastPos != sceneNode.position ||
            lastAngles != sceneNode.angles;

        if(doEnable)
            dBodyEnable(Body);

        if(lastPos != sceneNode.position)
            dBodySetPosition(Body, sceneNode.position.x,sceneNode.position.y,sceneNode.position.z);

        if(lastAngles != sceneNode.angles)
            dBodySetQuaternion(Body, sceneNode.rotation.quaternion);

        //TODO: use CopyPosition to save mem traffic
        auto pos = dBodyGetPosition(Body);
        quat rot;
        dBodyCopyQuaternion(Body, rot.quaternion);
        
        this.sceneNode.position = lastPos = vec3(pos[0..3]);
        this.sceneNode.rotation = rot;

        lastAngles = sceneNode.angles;
    }
    
private:
    vec3 lastPos;
    vec3 lastAngles;
    
    package dBodyID Body;  // the dynamics body
}