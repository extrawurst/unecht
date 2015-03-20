module app;

import unecht;

import imgui;

//TODO: this needs to be gone out of sight, nice objects to hide stuff like that from the user
void debugRender(double _time)
{
	imguiDrawText(10, 10, TextAlign.left, "Free text", RGBA(32, 192, 32, 192));
	imguiRender(ue.application.mainWindow.size.width, ue.application.mainWindow.size.height);
};

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
	ue.debugTick ~= &debugRender;

	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - hello world sample";

	ue.hookStartup = () {
		auto newE = UEEntity.create();

		import unecht.core.components.misc;

		//auto mesh = newE.addComponent!UEMesh;
		//mesh.setDefaultRect();
		//newE.addComponent!UERenderer;

		// startup imgui
		{
			import std.file;
			import std.path;
			import std.exception;
			
			string fontPath = thisExePath().dirName().buildPath(".").buildPath("DroidSans.ttf");
			
			enforce(imguiInit(fontPath));
		}
	};
}
