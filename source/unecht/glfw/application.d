module unecht.glfw.application;

import std.stdio;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.imgui.imgui;
import derelict.freeimage.freeimage;

import unecht.glfw.window;
import unecht.glfw.joysticks;
import unecht.core.types;

public import unecht.glfw.types;

import unecht;
import unecht.core.components.camera;
import unecht.core.components.misc;
import unecht.core.components.internal.gui;
import unecht.core.stdex;

version(UEProfiling) import unecht.core.profiler;

///
struct UEApplication
{
	UEWindow mainWindow;
	UEEventsSystem events;
	UEEntity rootEntity;
    private GLFWJoysticks joysticks;

    version(UEProfiling)
    {
        DespikerSender sender;
    }

	/// contains the game loop is run in main function
	int run()
	{
        version(UEProfiling)
        {
            profiler = new Profiler(storage);
            sender = new DespikerSender([profiler]);
        }

		DerelictFI.load();
		DerelictGL3.load();
		DerelictGLFW3.load();
        DerelictImgui.load();

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

        version(none)
        {
            import core.memory;
            GC.disable();
        }

		while (!mainWindow.shouldClose)
		{
            import std.datetime:StopWatch,TickDuration,AutoStart;
            auto sw = StopWatch(AutoStart.yes);
            scope(exit)
            {
                TickDuration a = sw.peek();
                import unecht.core.profiler;
                UEProfiling.addFrametime(a,UEGui.framerate);
            }

            {
                version(UEProfiling)
                auto frame = Zone(profiler, "frame");

                {
                    version(UEProfiling)
                    auto profZone = Zone(profiler, "events.cleanup");
        		    events.cleanUp();
                }

        		ue.tickTime = glfwGetTime();

                {
                    UEGui.startFrame();
                }

                {
                    version(UEProfiling)
                        auto profZone = Zone(profiler, "fibers run");
                    
                    UEFibers.runFibers();
                }

                {
                    version(UEProfiling)
                    auto profZone = Zone(profiler, "scene update");

        		    ue.scene.update();
                }

                {
                    version(UEProfiling)
                    auto profZone = Zone(profiler, "render update");

        		    render();
                }

        		version(UEIncludeEditor)
        		{
                    {
                        version(UEProfiling)
                        auto profZone = Zone(profiler, "render editor");

        			    import unecht.core.components._editor:EditorRootComponent;
        			    EditorRootComponent.renderEditor();
                    }
        		}

                {
                    version(UEProfiling)
                    auto profZone = Zone(profiler, "render gui");

                    UEGui.renderGUI();
                }

                {
                    version(UEProfiling)
                    auto profZone = Zone(profiler, "vertical sync");

                    mainWindow.swapBuffers();
                }

                {
                    version(UEProfiling)
                    auto profZone = Zone(profiler, "update joysticks");

                    joysticks.update();
                }

                {
                    version(UEProfiling)
                    auto profZone = Zone(profiler, "poll events");

        		    glfwPollEvents();
                }

                version(none)
                {
                    version(UEProfiling)
                    auto profZone = Zone(profiler, "gc");
                    GC.collect();
                }
            }

            version(UEProfiling)
            sender.update();
		}

		return 0;
	}

	/// initiate application closing
	void terminate()
	{
		mainWindow.close();
	}

    ///
    void openProfiler()
    {
        version(UEProfiling)
        {
            if(sender)
            {
                if(!sender.sending)
                {
                    try sender.startDespiker();
                    catch(Exception e)
                    {
                        import std.stdio;
                        writefln("error starting despiker binary");
                    }
                }
            }
        }
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

        ev.keyEvent.mods.setFromBitMaskGLFW(mods);

   		events.trigger(ev);
	}

	void glfwOnMouseMove(double x, double y)
	{
        UEEvent ev;
        ev.eventType = UEEventType.mousePos;
        ev.mousePosEvent.x = x;
        ev.mousePosEvent.y = y;

        populateCurrentKeyMods(ev.mousePosEvent.mods);

        events.trigger(ev);
	}

	void glfwOnMouseButton(int button, int action, int mods)
	{
        UEEvent ev;
        ev.eventType = UEEventType.mouseButton;
        ev.mouseButtonEvent.button = button;
        ev.mouseButtonEvent.action = (action == GLFW_PRESS) ? UEEvent.MouseButtonEvent.Action.down : UEEvent.MouseButtonEvent.Action.up;

        ev.mouseButtonEvent.mods.setFromBitMaskGLFW(mods);

        events.trigger(ev);
	}

    void glfwOnMouseScroll(double xoffset, double yoffset)
    {
        UEEvent ev;
        ev.eventType = UEEventType.mouseScroll;
        ev.mouseScrollEvent.xoffset = xoffset;
        ev.mouseScrollEvent.yoffset = yoffset;

        populateCurrentKeyMods(ev.mousePosEvent.mods);

        events.trigger(ev);
    }

	void glfwOnChar(uint codepoint)
	{
		UEEvent ev;
		ev.eventType = UEEventType.text;
		ev.textEvent.character = cast(dchar)codepoint;

        populateCurrentKeyMods(ev.textEvent.mods);

		events.trigger(ev);
	}

	void glfwOnWndSize(int width, int height)
	{
		UEEvent ev;
		ev.eventType = UEEventType.windowSize;
		ev.windowSizeEvent.size = UESize(width,height);

		ue.application.mainWindow.size = ev.windowSizeEvent.size;

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

        joysticks.init(events);

        import unecht.core.assetDatabase;
        UEAssetDatabase.refresh();

        insertGuiObj();

        insertPhysicsObj();

		version(UEIncludeEditor)insertEditorEntity();

		if(ue.hookStartup)
			ue.hookStartup();

        version(UEIncludeEditor)ue.scene.playing = false;
	}

    void insertGuiObj()
    {
        auto newE = UEEntity.create("gui");
        newE.addComponent!UEGui;
    }

    void insertPhysicsObj()
    {
        auto newE = UEEntity.create("physics");
        import unecht.core.components.physics;
        newE.addComponent!UEPhysicsSystem;
    }

	version(UEIncludeEditor)void insertEditorEntity()
	{
		auto newE = UEEntity.create("editor");
		import unecht.core.components._editor:EditorRootComponent;
		newE.addComponent!EditorRootComponent;
	}

	void render()
	{
		auto cams = ue.scene.gatherAllComponents!UECamera;

		foreach(cam; cams)
		{
			if(cam.enabled)
				cam.render();
		}
	}

    ///
    void populateCurrentKeyMods(ref EventModKeys mods)
    {
        mods.set(glfwGetKey(mainWindow.window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS,
            glfwGetKey(mainWindow.window, GLFW_KEY_LEFT_CONTROL) == GLFW_PRESS,
            glfwGetKey(mainWindow.window, GLFW_KEY_LEFT_ALT) == GLFW_PRESS,
            glfwGetKey(mainWindow.window, GLFW_KEY_LEFT_SUPER) == GLFW_PRESS);
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
