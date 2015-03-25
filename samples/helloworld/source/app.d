module app;

import unecht;

final class TestComponent : UEComponent {

	mixin(UERegisterComponent!());

	override void onCreate() {
		super.onCreate;

		registerEvent(UEEventType.key, &OnKeyEvent);

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

	override void onUpdate() {
		super.onUpdate;

		auto time = ue.tickTime;
		this.sceneNode.position = vec3(sin(time)*2.0f,0,0);
	}

	void OnKeyEvent(UEEvent _ev)
	{
		import std.stdio;

		//writefln("key: %s",_ev.keyEvent);

		if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down &&
			_ev.keyEvent.key == UEKey.esc)
			ue.application.terminate();
	}
}

shared static this()
{
	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - hello world sample";

	ue.hookStartup = () {
		auto newE = UEEntity.create("app test entity");
		newE.addComponent!TestComponent;

		auto newE2 = UEEntity.create("app test entity 2");
		newE2.sceneNode.position = vec3(0,2,-10);

		import unecht.core.components.camera;
		auto cam = newE2.addComponent!UECamera;
		cam.clearColor = vec4(1,0,0,1);

		auto newEs = UEEntity.create("sub entity");
		newEs.sceneNode.position = vec3(10,0,0);
		newEs.sceneNode.parent = newE.sceneNode;
	};
}
