module unecht.core.components.physics;

import derelict.ode.ode;
import derelict.util.system;

import unecht.core.component;

import gl3n.linalg;

version(UEProfiling)import unecht.core.profiler;

///
private quat ode2quat(in dReal* _rotMatrix) pure
{
    auto rot = Matrix!(float,3,4)(_rotMatrix[0..12]);
    mat3 m4rot = rot;
    return quat.from_matrix(m4rot);
}

///
final class UEPhysicsColliderPlane : UEComponent
{
    mixin(UERegisterComponent!());

    dGeomID Geom;

    override void onCreate() {
        super.onCreate;

        // Create a ground plane in our collision space by passing Space as the first argument to dCreatePlane.
        // The next four parameters are the planes normal (a, b, c) and distance (d) according to the plane
        // equation a*x+b*y+c*z=d and must have length 1
        Geom = dCreatePlane(UEPhysicsSystem.space, 0, 1, 0, 0);
    }
}

///
final class UEPhysicsColliderBox : UEComponent
{
    mixin(UERegisterComponent!());
    
    dGeomID _geom;

    vec3 size = vec3(2);
    
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
            auto pos = this.sceneNode.position;
            dGeomSetPosition(_geom, pos.x, pos.y, pos.z);
        }
    }

    override void onUpdate() {
        if(!_rigidBody)
        {
            auto pos = dGeomGetPosition(_geom);
            float[4] qrot;
            dGeomGetQuaternion(_geom,qrot);
            
            quat rot = quat(qrot[0],qrot[1],qrot[2],qrot[3]);
            
            this.sceneNode.position = vec3(pos[0..3]);
            this.sceneNode.rotation = rot;
        }
    }

private:
    UEPhysicsBody _rigidBody;
}

///
final class UEPhysicsColliderSphere : UEComponent
{
    mixin(UERegisterComponent!());

    float rad=1.0f;

    bool isTrigger = false;
    
    override void onCreate() {
        super.onCreate;
        
        auto rigidBody = entity.getComponent!UEPhysicsBody;

        _geom = dCreateSphere(UEPhysicsSystem.space, rad);

        dGeomSetData(_geom, cast(void*)this);

        if(rigidBody)
            dGeomSetBody(_geom, rigidBody.Body);
    }

private:
    dGeomID _geom;
}

///
final class UEPhysicsSystem : UEComponent {
    
    mixin(UERegisterComponent!());
    
    static dWorldID world;
    static dSpaceID space;
    
    private static bool initialised;
    private static dJointGroupID contactgroup;
    
    override void onCreate() {
        if(!initialised)
        {
            DerelictODE.load();
            
            dInitODE ();
            
            // Create a new, empty world and assign its ID number to World. Most applications will only need one world.
            world = dWorldCreate();
            
            // Create a new collision space and assign its ID number to Space, passing 0 instead of an existing dSpaceID.
            // There are three different types of collision spaces we could create here depending on the number of objects 
            // in the world but dSimpleSpaceCreate is fine for a small number of objects. If there were more objects we
            // would be using dHashSpaceCreate or dQuadTreeSpaceCreate (look these up in the ODE docs)  
            space = dSimpleSpaceCreate(null);
            
            // Create a joint group object and assign its ID number to contactgroup. dJointGroupCreate used to have a 
            // max_size parameter but it is no longer used so we just pass 0 as its argument.
            contactgroup = dJointGroupCreate(0);
            
            // Now we set the gravity vector for our world by passing World as the first argument to dWorldSetGravity.
            // Earth's gravity vector would be (0, -9.81, 0) assuming that +Y is up. I found that a lighter gravity looked
            // more realistic in this case. 
            dWorldSetGravity(world, 0, -1, 0);
            
            // These next two functions control how much error correcting and constraint force mixing occurs in the world.
            // Don't worry about these for now as they are set to the default values and we could happily delete them from
            // this example. Different values, however, can drastically change the behaviour of the objects colliding, so
            // I suggest you look up the full info on them in the ODE docs.
            dWorldSetERP(world, 0.2);
            
            dWorldSetCFM(world, 1e-5);
            
            // This function sets the velocity that interpenetrating objects will separate at. The default value is infinity.
            dWorldSetContactMaxCorrectingVel(world, 0.9);
            
            // This function sets the depth of the surface layer around the world objects. Contacts are allowed to sink into
            // each other up to this depth. Setting it to a small value reduces the amount of jittering between contacting
            // objects, the default value is 0.     
            dWorldSetContactSurfaceLayer(world, 0.001);
            
            // To save some CPU time we set the auto disable flag to 1. This means that objects that have come to rest (based
            // on their current linear and angular velocity) will no longer participate in the simulation, unless acted upon
            // by a moving object. If you do not want to use this feature then set the flag to 0. You can also manually enable
            // or disable objects using dBodyEnable and dBodyDisable, see the docs for more info on this.
            dWorldSetAutoDisableFlag(world, 1);
            
            initialised = true;
        }
    }

    ///
    override void onUpdate() {
        version(UEProfiling)
        auto profZone = Zone(profiler, "physics update");

        _collisionsThisFrame = 0;

        {
            version(UEProfiling)
            auto profZone2 = Zone(profiler, "physics collide");
            /++
             + dSpaceCollide determines which pairs of geoms in the space we pass to it may potentially intersect. 
             + We must also pass the address of a callback function that we will provide. 
             + The callback function is responsible for determining which of the potential intersections 
             + are actual collisions before adding the collision joints to our joint group called contactgroup, 
             + this gives us the chance to set the behaviour of these joints before adding them to the group. 
             + The second parameter is a pointer to any data that we may want to pass to our callback routine. 
             + We will cover the details of the nearCallback routine in the next section.
             +/
            dSpaceCollide(space, null, &nearCallback);
        }

        {
            version(UEProfiling)
            auto profZone2 = Zone(profiler, "physics step");
            /+ 
             + Now we advance the simulation by calling dWorldQuickStep. 
             + This is a faster version of dWorldStep but it is also 
             + slightly less accurate. As well as the World object ID we also pass a step size value. 
             + In each step the simulation is updated by a certain number of smaller steps or iterations. 
             + The default number of iterations is 20 but you can change this by calling 
             + dWorldSetQuickStepNumIterations.
            +/
            dWorldQuickStep(world, 0.05);
        }
        
        // Remove all temporary collision joints now that the world has been stepped
        dJointGroupEmpty(contactgroup);

        propagateCollisions();
    }

    ///
    void propagateCollisions()
    {
        version(UEProfiling)
        auto profZone = Zone(profiler, "physics propagate");

        foreach(col; _collisions[0.._collisionsThisFrame])
        {
            if(col.c1)
                col.c1.entity.broadcast!"onCollision"(col.c2);
            if(col.c2)
                col.c2.entity.broadcast!"onCollision"(col.c1);
        }
    }

    ///
    private struct Collision
    {
        UEComponent c1,c2;
    }

    private static Collision[1024] _collisions;
    private static uint _collisionsThisFrame;

    ///
    private extern(C) @nogc nothrow static void nearCallback(void *data, dGeomID o1, dGeomID o2)
    {
        // Get the dynamics body for each geom
        dBodyID b1 = dGeomGetBody(o1);
        dBodyID b2 = dGeomGetBody(o2);

        void* gData1 = dGeomGetData(o1);
        void* gData2 = dGeomGetData(o2);
        
        static immutable MAX_CONTACTS = 128;
        // Create an array of dContact objects to hold the contact joints
        dContact[MAX_CONTACTS] contact;
        
        // Now we set the joint properties of each contact. Going into the full details here would require a tutorial of its
        // own. I'll just say that the members of the dContact structure control the joint behaviour, such as friction,
        // velocity and bounciness. See section 7.3.7 of the ODE manual and have fun experimenting to learn more.
        foreach (i; 0..MAX_CONTACTS)
        {
            contact[i].surface.mode = dContactBounce | dContactSoftCFM;
            contact[i].surface.mu = dInfinity;
            contact[i].surface.mu2 = 0;
            contact[i].surface.bounce = 0.01;   
            contact[i].surface.bounce_vel = 0.1;
            contact[i].surface.soft_cfm = 0.01;
        }
        
        // Here we do the actual collision test by calling dCollide. It returns the number of actual contact points or zero
        // if there were none. As well as the geom IDs, max number of contacts we also pass the address of a dContactGeom
        // as the fourth parameter. dContactGeom is a substructure of a dContact object so we simply pass the address of
        // the first dContactGeom from our array of dContact objects and then pass the offset to the next dContactGeom
        // as the fifth paramater, which is the size of a dContact structure. That made sense didn't it?  
        if (int numc = dCollide(o1, o2, MAX_CONTACTS, &contact[0].geom, dContact.sizeof))
        {   
            // To add each contact point found to our joint group we call dJointCreateContact which is just one of the many
            // different joint types available.  
            foreach (i; 0..numc)
            {
                // dJointCreateContact needs to know which world and joint group to work with as well as the dContact
                // object itself. It returns a new dJointID which we then use with dJointAttach to finally create the
                // temporary contact joint between the two geom bodies.
                dJointID c = dJointCreateContact(UEPhysicsSystem.world, contactgroup, contact.ptr + i);
                
                dJointAttach(c, b1, b2);    
            }

            auto component1 = cast(UEComponent)gData1;
            auto component2 = cast(UEComponent)gData2;

            if(_collisionsThisFrame<_collisions.length)
                _collisions[_collisionsThisFrame++] = Collision(component1,component2);
            else
                assert(false);
        }
    }
}

///
final class UEPhysicsBody : UEComponent 
{
    mixin(UERegisterComponent!());

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

    dBodyID Body;  // the dynamics body
}