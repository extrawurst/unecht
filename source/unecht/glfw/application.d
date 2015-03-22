module unecht.glfw.application;

import std.stdio;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;

import unecht.glfw.window;
import unecht.core.types;

public import unecht.glfw.types;

import unecht;
import unecht.core.components.camera;
import unecht.core.components.misc;

///
struct UEApplication
{
	UEWindow mainWindow;
	UEEventsSystem events;
	UEEntity rootEntity;

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

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glDisable(GL_DEPTH_TEST);

		while (!mainWindow.shouldClose)
		{
			events.cleanUp();
			ue.tickTime = glfwGetTime();

			ue.scene.update();

			render();

			foreach(f; ue.debugTick)
				f(glfwGetTime());

			version(UEIncludeEditor)
			{
				import unecht.core.components.editor;
				EditorComponent.renderEditor();
			}

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
		UEEvent ev;
		ev.eventType = UEEventType.key;
		ev.keyEvent.key = cast(UEKey)key;
		ev.keyEvent.action = UEEvent.KeyEvent.Action.Down;

		if(action == GLFW_RELEASE)
			ev.keyEvent.action = UEEvent.KeyEvent.Action.Up;
		else if(action == GLFW_REPEAT)
			ev.keyEvent.action = UEEvent.KeyEvent.Action.Repeat;

		events.trigger(ev);
	}

	void glfwOnChar(uint codepoint)
	{
		UEEvent ev;
		ev.eventType = UEEventType.text;
		ev.textEvent.character = cast(dchar)codepoint;

		events.trigger(ev);
	}

	void glfwOnWndSize(int width, int height)
	{
		UEEvent ev;
		ev.eventType = UEEventType.windowSize;
		ev.windowSizeEvent.size = UESize(width,height);

		events.trigger(ev);
	}

	void glfwOnFramebufferSize(int width, int height)
	{
		UEEvent ev;
		ev.eventType = UEEventType.framebufferSize;
		ev.framebufferSizeEvent.size = UESize(width,height);
		
		events.trigger(ev);
	}

	void glfwOnWindowFocus(bool gainedFocus)
	{
		UEEvent ev;
		ev.eventType = UEEventType.windowFocus;
		ev.focusEvent.gainedFocus = gainedFocus;
		
		events.trigger(ev);
	}

private:

	bool initGLFW()
	{
		glfwSetErrorCallback(&error_callback);

		return glfwInit()!=0;
	}

	void startEngine()
	{
		events = new UEEventsSystem();
		
		ue.events = events;

		ue.scene = new UEScenegraph();

		version(UEIncludeEditor)
		{
			insertEditorEntity();
		}

		if(ue.hookStartup)
			ue.hookStartup();
	}

	void insertEditorEntity()
	{
		auto newE = UEEntity.create("editor");

		import unecht.core.components.editor;
		newE.addComponent!EditorComponent;
	}

	void render()
	{
		auto cams = ue.scene.gatherAllComponents!UECamera;

		foreach(cam; cams)
			cam.render();
	}
}

private nothrow extern(C) void error_callback(int error, const(char)* description)
{
	try {
		import std.conv;
		writefln("glfw err: %s '%s'", error, to!string(description));
	}
	catch{}
}
