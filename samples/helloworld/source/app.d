module app;

import unecht;

import derelict.ode.ode;
import derelict.util.system;

dWorldID World;
dJointGroupID contactgroup;
dSpaceID Space;

extern(C) @nogc nothrow static void nearCallback (void *data, dGeomID o1, dGeomID o2)
{
	// Get the dynamics body for each geom
	dBodyID b1 = dGeomGetBody(o1);
	dBodyID b2 = dGeomGetBody(o2);

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
			dJointID c = dJointCreateContact(World, contactgroup, contact.ptr + i);
			
			dJointAttach(c, b1, b2);	
		}
	}
}

quat ode2quat(in dReal* _rotMatrix) pure
{
	auto rot = Matrix!(float,3,4)(_rotMatrix[0..12]);
	mat3 m4rot = rot;
	return quat.from_matrix(m4rot);
}

final class TestPhysicsObject : UEComponent {
    mixin(UERegisterComponent!());

    dBodyID Body;  // the dynamics body
    dGeomID Geom;  // geometry representing this body

    override void onCreate() {
        super.onCreate;

        // This brings us to the end of the world settings, now we have to initialize the objects themselves.
        // Create a new body for our object in the world and get its ID.
        Body = dBodyCreate(World);
        
        // Next we set the position of the new body
        dBodySetPosition(Body, 0, 10, -5);
        
        // Here I have set the initial linear velocity to stationary and let gravity do the work, but you can experiment
        // with the velocity vector to change the starting behaviour. You can also set the rotational velocity for the new
        // body using dBodySetAngularVel which takes the same parameters.
        dBodySetLinearVel(Body, 0,0,0);
        
        // To start the object with a different rotation each time the program runs we create a new matrix called R and use
        // the function dRFromAxisAndAngle to create a random initial rotation before passing this matrix to dBodySetRotation.
        dMatrix3 R;
        dRFromAxisAndAngle(R, dRandReal() * 2.0 - 1.0,
            dRandReal() * 2.0 - 1.0,
            dRandReal() * 2.0 - 1.0,
            dRandReal() * 10.0 - 5.0);
        
        dBodySetRotation(Body, R);
        
        // At this point we could add our own user data using dBodySetData but in this example it isn't used.
        size_t i = 0;
        dBodySetData(Body, cast(void*)i);
        
        // Now we need to create a box mass to go with our geom. First we create a new dMass structure (the internals
        // of which aren't important at the moment) then create an array of 3 float (dReal) values and set them
        // to the side lengths of our box along the x, y and z axes. We then pass the both of these to dMassSetBox with a
        // pre-defined DENSITY value of 0.5 in this case.
        dMass m;
        
        dReal[3] sides;
        sides[0] = 2.0;
        sides[1] = 2.0;
        sides[2] = 2.0;
        static immutable DENSITY = 0.5f;
        dMassSetBox(&m, DENSITY, sides[0], sides[1], sides[2]);
        
        // We can then apply this mass to our objects body.
        dBodySetMass(Body, &m);
        
        // Here we create the actual geom object using dCreateBox. Note that this also adds the geom to our 
        // collision space and sets the size of the geom to that of our box mass.
        Geom = dCreateBox(Space, sides[0], sides[1], sides[2]);
        
        // And lastly we want to associate the body with the geom using dGeomSetBody. Setting a body on a geom automatically
        // combines the position vector and rotation matrix of the body and geom so that setting the position or orientation
        // of one will set the value for both objects. The ODE docs have a lot more to say about the geom functions.
        dGeomSetBody(Geom, Body);
    }

    override void onUpdate() {
        auto pos = dGeomGetPosition (Geom);
        auto R = dGeomGetRotation (Geom);
        
        this.sceneNode.position = vec3(pos[0..3]);
        this.sceneNode.rotation = ode2quat(R);
    }
}

final class TestODESystem : UEComponent {
	
	mixin(UERegisterComponent!());
	
	override void onCreate() {
		DerelictODE.load();

		dInitODE ();
		
		// Create a new, empty world and assign its ID number to World. Most applications will only need one world.
		World = dWorldCreate();
		
		// Create a new collision space and assign its ID number to Space, passing 0 instead of an existing dSpaceID.
		// There are three different types of collision spaces we could create here depending on the number of objects 
		// in the world but dSimpleSpaceCreate is fine for a small number of objects. If there were more objects we
		// would be using dHashSpaceCreate or dQuadTreeSpaceCreate (look these up in the ODE docs)	
		Space = dSimpleSpaceCreate(null);
		
		// Create a joint group object and assign its ID number to contactgroup. dJointGroupCreate used to have a 
		// max_size parameter but it is no longer used so we just pass 0 as its argument.
		contactgroup = dJointGroupCreate(0);

		// Create a ground plane in our collision space by passing Space as the first argument to dCreatePlane.
		// The next four parameters are the planes normal (a, b, c) and distance (d) according to the plane
		// equation a*x+b*y+c*z=d and must have length 1
		dCreatePlane(Space, 0, 1, 0, 0);
		
		// Now we set the gravity vector for our world by passing World as the first argument to dWorldSetGravity.
		// Earth's gravity vector would be (0, -9.81, 0) assuming that +Y is up. I found that a lighter gravity looked
		// more realistic in this case.	
		dWorldSetGravity(World, 0, -1, 0);

		// These next two functions control how much error correcting and constraint force mixing occurs in the world.
		// Don't worry about these for now as they are set to the default values and we could happily delete them from
		// this example. Different values, however, can drastically change the behaviour of the objects colliding, so
		// I suggest you look up the full info on them in the ODE docs.
		dWorldSetERP(World, 0.2);
		
		dWorldSetCFM(World, 1e-5);
		
		// This function sets the velocity that interpenetrating objects will separate at. The default value is infinity.
		dWorldSetContactMaxCorrectingVel(World, 0.9);
		
		// This function sets the depth of the surface layer around the world objects. Contacts are allowed to sink into
		// each other up to this depth. Setting it to a small value reduces the amount of jittering between contacting
		// objects, the default value is 0. 	
		dWorldSetContactSurfaceLayer(World, 0.001);

		// To save some CPU time we set the auto disable flag to 1. This means that objects that have come to rest (based
		// on their current linear and angular velocity) will no longer participate in the simulation, unless acted upon
		// by a moving object. If you do not want to use this feature then set the flag to 0. You can also manually enable
		// or disable objects using dBodyEnable and dBodyDisable, see the docs for more info on this.
		dWorldSetAutoDisableFlag(World, 1);
	}

	override void onUpdate() {
		super.onUpdate;

		/++
		 + dSpaceCollide determines which pairs of geoms in the space we pass to it may potentially intersect. 
		 + We must also pass the address of a callback function that we will provide. 
		 + The callback function is responsible for determining which of the potential intersections 
		 + are actual collisions before adding the collision joints to our joint group called contactgroup, 
		 + this gives us the chance to set the behaviour of these joints before adding them to the group. 
		 + The second parameter is a pointer to any data that we may want to pass to our callback routine. 
		 + We will cover the details of the nearCallback routine in the next section.
		 +/
		dSpaceCollide(Space, null, &nearCallback);
		
		/+ 
		 + Now we advance the simulation by calling dWorldQuickStep. 
		 + This is a faster version of dWorldStep but it is also 
		 + slightly less accurate. As well as the World object ID we also pass a step size value. 
		 + In each step the simulation is updated by a certain number of smaller steps or iterations. 
		 + The default number of iterations is 20 but you can change this by calling 
		 + dWorldSetQuickStepNumIterations.
		+/
		dWorldQuickStep(World, 0.05);

		// Remove all temporary collision joints now that the world has been stepped
		dJointGroupEmpty(contactgroup);
	}
	
}

final class TestControls : UEComponent
{
    mixin(UERegisterComponent!());

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();
            
            if(_ev.keyEvent.key == UEKey.enter)
            {
                spawnBox();
            }
        }
    }

    static void spawnBox()
    {
        auto newE = UEEntity.create("ode entity");
        newE.addComponent!TestGfxBox;
        newE.addComponent!TestPhysicsObject;
    }
}

final class TestGfxBox : UEComponent {
	
	mixin(UERegisterComponent!());

	override void onCreate() {
		super.onCreate;

		import unecht.core.components.misc;
		import unecht.gl.vertexBufferObject;
		import unecht.gl.vertexArrayObject;

		auto renderer = this.entity.addComponent!UERenderer;
		auto mesh = this.entity.addComponent!UEMesh;
	
		renderer.material = this.entity.addComponent!UEMaterial;
		renderer.material.setProgram(UEMaterial.vs_tex,UEMaterial.fs_tex, "tex");
		renderer.material.depthTest = true;
		renderer.mesh = mesh;

		mesh.vertexArrayObject = new GLVertexArrayObject();
		mesh.vertexArrayObject.bind();

		auto upLF = vec3(-1,1,-1);
		auto upLB = vec3(-1,1,1);
		auto upRB = vec3(1,1,1);
		auto upRF = vec3(1,1,-1);

		auto dnLF = vec3(-1,-1,-1);
		auto dnLB = vec3(-1,-1,1);
		auto dnRB = vec3(1,-1,1);
		auto dnRF = vec3(1,-1,-1);

		mesh.vertexBuffer = new GLVertexBufferObject([
				//top
				upLF,upLB,upRB,upRF,
				//front
				upLF,upRF,dnLF,dnRF,
				//bottom
				dnLF,dnRF,dnLB,dnRB,
				//left
				upLF,upLB,dnLF,dnLB,
				//back
				upRB,upLB,dnRB,dnLB,
				//right
				upRB,upRF,dnRB,dnRF
			]);

		auto ul = vec2(0,0);
		auto ur = vec2(1,0);
		auto lr = vec2(1,1);
		auto ll = vec2(0,1);

		mesh.uvBuffer = new GLVertexBufferObject([
				//top
				ul,ur,ll,lr,
				//front
				ul,ur,ll,lr,
				//bottom
				ul,ur,ll,lr,
				//left
				ul,ur,ll,lr,
				//back
				ul,ur,ll,lr,
				//right
				ul,ur,ll,lr,
			]);

		mesh.normalBuffer = new GLVertexBufferObject([
				// top
				vec3(0,1,0),vec3(0,1,0),vec3(0,1,0),vec3(0,1,0),
				// front
				vec3(0,0,-1),vec3(0,0,-1),vec3(0,0,-1),vec3(0,0,-1),
				// bottom
				vec3(0,-1,0),vec3(0,-1,0),vec3(0,-1,0),vec3(0,-1,0),
				// left
				vec3(-1,0,0),vec3(-1,0,0),vec3(-1,0,0),vec3(-1,0,0),
				// back
				vec3(0,0,1),vec3(0,0,1),vec3(0,0,1),vec3(0,0,1),
				// right
				vec3(1,0,0),vec3(1,0,0),vec3(1,0,0),vec3(1,0,0)
			]);

		mesh.indexBuffer = new GLVertexBufferObject([
				//top
				0,1,2, 
				0,2,3,
				//front
				4,5,6,
				5,7,6,
				//bottom
				8,9,10,
				9,11,10,
				//left
				12,13,14, 13,14,15,
				//back
				16,17,18, 17,18,19,
				//right
				20,21,22, 21,23,22
			]);
		mesh.vertexArrayObject.unbind();
	}
}

shared static this()
{
	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - hello world sample";

	ue.hookStartup = () {
		auto newE = UEEntity.create("app test entity");
        newE.addComponent!TestControls;
		newE.addComponent!TestODESystem;

        TestControls.spawnBox();

		auto newE2 = UEEntity.create("app test entity 2");
		newE2.sceneNode.position = vec3(0,3,-20);

		import unecht.core.components.camera;
		auto cam = newE2.addComponent!UECamera;
		cam.clearColor = vec4(1,0,0,1);

		auto newEs = UEEntity.create("sub entity");
		newEs.sceneNode.position = vec3(10,0,0);
		newEs.sceneNode.parent = newE.sceneNode;
	};
}