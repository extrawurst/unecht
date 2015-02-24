module unecht.glfw.application;

import std.stdio;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;

import unecht.glfw.window;
import unecht.core.types;

public import unecht.glfw.types;

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
		DerelictGL3.load();
		DerelictGLFW3.load();

		if(!initGLFW())
			return -1;

		scope(exit) glfwTerminate();

		if(!mainWindow.create(ue.windowSettings.size,ue.windowSettings.title))
			return -1;

		scope(exit) mainWindow.destroy();
			
		DerelictGL3.reload();

		startEngine();

		glClearColor(0.8f, 0.8f, 0.8f, 1.0f);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glDisable(GL_DEPTH_TEST);

		while (!mainWindow.shouldClose)
		{
			events.cleanUp();

			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

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
		ev.eventType = EventType.key;
		ev.keyEvent.key = cast(UEKey)key;
		ev.keyEvent.action = Event.KeyEvent.Action.Down;

		if(action == GLFW_RELEASE)
			ev.keyEvent.action = Event.KeyEvent.Action.Up;
		else if(action == GLFW_REPEAT)
			ev.keyEvent.action = Event.KeyEvent.Action.Repeat;

		events.trigger(ev);
	}

	void glfwOnChar(uint codepoint)
	{
		Event ev;
		ev.eventType = EventType.text;
		ev.textEvent.character = cast(dchar)codepoint;

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