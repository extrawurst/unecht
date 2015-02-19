
import unecht;

//TODO: this needs to be gone out of sight, nice objects to hide stuff like that from the user
void debugRender(double _time)
{
	import derelict.opengl3.gl;
	import derelict.opengl3.deprecatedFunctions;
	import derelict.opengl3.deprecatedConstants;

	float ratio = ue.application.mainWindow.size.width / cast(float)  ue.application.mainWindow.size.height;
	
	glViewport(0, 0, ue.windowSettings.size.width, ue.windowSettings.size.height);
	glClear(GL_COLOR_BUFFER_BIT);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(-ratio, ratio, -1.0f, 1.0f, 1.0f, -1.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glRotatef(cast(float) _time * 50.0f, 0.0f, 0.0f, 1.0f);
	glBegin(GL_TRIANGLES);
	glColor3f(1.0f, 0.0f, 0.0f);
	glVertex3f(-0.6f, -0.4f, 0.0f);
	glColor3f(0.0f, 1.0f, 0.0f);
	glVertex3f(0.6f, -0.4f, 0.0f);
	glColor3f(0.0f, 0.0f, 1.0f);
	glVertex3f(0.0f, 0.6f, 0.0f);
	glEnd();
};

final class TestComponent : Component {

	override void onCreate() {
		super.onCreate;

		registerEvent(EventType.Key, &OnKeyEvent);

		entity.addComponent!Renderer();
	}

	override void onUpdate() {
		super.onUpdate;

		//TODO:
		//transform.Rotate();
	}

	void OnKeyEvent(Event _ev)
	{
		import std.stdio;

		writefln("key: %s",_ev.keyEvent);

		if(_ev.keyEvent.action == Event.KeyEvent.Action.Down &&
			_ev.keyEvent.code == 1)
			ue.application.terminate();
	}
}

shared static this()
{
	ue.debugTick ~= &debugRender;

	ue.windowSettings.size.width = 640;
	ue.windowSettings.size.height = 320;
	ue.windowSettings.title = "unecht - hello world sample";

	import std.traits;
	ue.startComponent = fullyQualifiedName!TestComponent;
}
