module unecht.glfw.application;

import std.stdio;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl;

import unecht.glfw.window;
import unecht.core.types;

import unecht;

extern(C) void error_callback(int error, const(char)* description) nothrow
{
	try {
		import std.conv;
		writefln("glfw err: %s '%s'", error, to!string(description));
	}
	catch{}
}

///
struct Application
{
	Window mainWindow;
	EventsSystem events;

	/// contains the game loop is run in main function
	int run()
	{
		DerelictGL.load();
		DerelictGLFW3.load();

		if(!initGLFW())
			return -1;

		scope(exit) glfwTerminate();

		if(!mainWindow.create(ue.windowSettings.size,ue.windowSettings.title))
			return -1;

		scope(exit) mainWindow.destroy();
			
		DerelictGL.reload();

		startEngine();

		while (!mainWindow.shouldClose)
		{
			events.cleanUp();

			foreach(f; ue.debugTick)
				f(glfwGetTime());

			mainWindow.swapBuffers();

			glfwPollEvents();
		}

		return 0;
	}

	/// initiate application closing
	void terminate()
	{
		mainWindow.close();
	}

package:
	void glfwOnKey(int key, int scancode, int action, int mods)
	{
		Event ev;
		ev.eventType = EventType.Key;
		ev.keyEvent.code = scancode;
		ev.keyEvent.action = Event.KeyEvent.Action.Down;

		if(action == GLFW_RELEASE)
			ev.keyEvent.action = Event.KeyEvent.Action.Up;
		else if(action == GLFW_REPEAT)
			ev.keyEvent.action = Event.KeyEvent.Action.Repeat;

		events.trigger(ev);
	}

	void glfwOnWndSize()
	{

	}

private:

	bool initGLFW()
	{
		glfwSetErrorCallback(&error_callback);

		return glfwInit()!=0;
	}

	void startEngine()
	{
		events = new EventsSystem();
		
		ue.events = events;

		ue.currentScene = Entity.create();

		ue.currentScene.addComponent(ue.startComponent);
	}
}