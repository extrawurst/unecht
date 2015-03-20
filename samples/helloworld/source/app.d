module app;

import unecht;

final class TestComponent : UEComponent {

	override void onCreate() {
		super.onCreate;

		registerEvent(UEEventType.key, &OnKeyEvent);
	}

	override void onUpdate() {
		super.onUpdate;

		//TODO:
		//transform.Rotate();
	}

	void OnKeyEvent(UEEvent _ev)
	{
		import std.stdio;

		writefln("key: %s",_ev.keyEvent);

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
		newE.sceneNode.position = vec3(1,0,0);

		auto newE2 = UEEntity.create("app test entity 2");
		newE2.sceneNode.position = vec3(1,0,0);

		auto newEs = UEEntity.create("sub entity");
		newEs.sceneNode.position = vec3(10,0,0);
		newEs.sceneNode.parent = newE.sceneNode;

		//import unecht.core.components.misc;
		//auto mesh = newE.addComponent!UEMesh;
		//mesh.setDefaultRect();
		//newE.addComponent!UERenderer;
	};
}
