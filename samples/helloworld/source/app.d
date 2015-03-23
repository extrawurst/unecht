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
		renderer.mesh = mesh;

		mesh.vertexArrayObject = new GLVertexArrayObject();
		mesh.vertexArrayObject.bind();

		mesh.vertexBuffer = new GLVertexBufferObject([
				vec3(-0.5,0.5,0),
				vec3(0,-0.5,0),
				vec3(0.5,0.5,0),
			]);

		mesh.normalBuffer = new GLVertexBufferObject([
				vec3(0,0,1),
				vec3(0,0,1),
				vec3(0,0,1),
			]);

		mesh.indexBuffer = new GLVertexBufferObject([0,1,2]);
		mesh.vertexArrayObject.unbind();
	}

	override void onUpdate() {
		super.onUpdate;
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
		newE2.sceneNode.position = vec3(0,1,-100);

		import unecht.core.components.camera;
		auto cam = newE2.addComponent!UECamera;
		cam.clearColor = vec4(1,0,0,1);

		auto newEs = UEEntity.create("sub entity");
		newEs.sceneNode.position = vec3(10,0,0);
		newEs.sceneNode.parent = newE.sceneNode;
	};
}
