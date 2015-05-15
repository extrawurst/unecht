module unecht.core.components.physics.system;

import derelict.ode.ode;
import derelict.util.system;

import unecht.core.component;
import unecht.core.defaultInspector;
import unecht.core.components.physics.material;

import gl3n.linalg;

version(UEProfiling)import unecht.core.profiler;

///
@UEDefaultInspector!UEPhysicsSystem
final class UEPhysicsSystem : UEComponent {
    
    mixin(UERegisterObject!());
    
    static dWorldID world;
    static dSpaceID space;
    
    private static bool initialised;
    private static dJointGroupID contactgroup;
    
    ///
    static void setGravity(vec3 _v)
    {
        dWorldSetGravity(world, _v.x,_v.y,_v.z);
    }

    ///
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
    override void onDestroy() {
        if(initialised)
        {
            if(world)
                dWorldDestroy(world);

            if(contactgroup)
                dJointGroupDestroy(contactgroup);

            world = null;
            contactgroup = null;

            initialised = false;

            dCloseODE();
        }
    }
    
    ///
    override void onUpdate() {
        version(UEProfiling)
        auto profZone = Zone(profiler, "physics update");
        
        _collisionsThisFrame = 0;

        // Remove all temporary collision joints
        dJointGroupEmpty(contactgroup);
        
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
        
        UEComponent comp1 = cast(UEComponent)gData1;
        UEComponent comp2 = cast(UEComponent)gData2;
        
        UEPhysicsMaterialInfo m1,m2;
        
        if(comp1)
            if(auto mat = comp1.entity.getComponent!UEPhysicsMaterial)
                m1 = mat.materialInfo;
        
        if(comp2)
            if(auto mat = comp2.entity.getComponent!UEPhysicsMaterial)
                m2 = mat.materialInfo;
        
        dSurfaceParameters surfaceParams;
        with(surfaceParams){
            mode = 0;
            
            if(m1.isBouncy || m2.isBouncy)
                mode = dContactBounce;
            
            mu = (m1.friction + m2.friction) / 2.0f;

            if(m1.friction >= dInfinity || m2.friction >= dInfinity)
                mu = dInfinity;

            //mu2 = 0;
            //rho = 0
            //rho2 = 0;
            //rhoN = 0;
            bounce = (m1.bouncyness + m2.bouncyness) / 2.0f;
            bounce_vel = 0.001;
            //soft_erp = 0;
            //soft_cfm = 0;
            //motion1 = 0;
            //motion2 = 0;
            //motionN = 0;
            //dReal slip1, slip2;
        }
        
        // Create an array of dContact objects to hold the contact joints
        static immutable CONTACT_COUNT = 32;
        dContact[CONTACT_COUNT] contacts;
        foreach(ref c; contacts)
            c.surface = surfaceParams;
        
        // Here we do the actual collision test by calling dCollide. It returns the number of actual contact points or zero
        // if there were none. As well as the geom IDs, max number of contacts we also pass the address of a dContactGeom
        // as the fourth parameter. dContactGeom is a substructure of a dContact object so we simply pass the address of
        // the first dContactGeom from our array of dContact objects and then pass the offset to the next dContactGeom
        // as the fifth paramater, which is the size of a dContact structure. That made sense didn't it?  
        if (int numc = dCollide(o1, o2, CONTACT_COUNT, &contacts[0].geom, dContact.sizeof))
        {   
            // To add each contact point found to our joint group we call dJointCreateContact which is just one of the many
            // different joint types available.  
            foreach (i; 0..numc)
            {
                // dJointCreateContact needs to know which world and joint group to work with as well as the dContact
                // object itself. It returns a new dJointID which we then use with dJointAttach to finally create the
                // temporary contact joint between the two geom bodies.
                dJointID c = dJointCreateContact(UEPhysicsSystem.world, contactgroup, &contacts[i]);
                
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
