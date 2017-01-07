module unecht.glfw.glfwapplication;

import std.stdio;

import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import derelict.imgui.imgui;
import derelict.freeimage.freeimage;

import unecht.glfw.glfwwindow;
import unecht.glfw.joysticks;
import unecht.core.types;

public import unecht.glfw.types;

import unecht.ue,
    unecht.core.application,
    unecht.core.window,
    unecht.core.entity,
    unecht.core.components.camera,
    unecht.core.components.misc,
    unecht.core.components.internal.gui,
    unecht.core.events,
    unecht.core.stdex;

version(EnableSteam) import unecht.steamaccess;
version(UEProfiling) import unecht.core.profiler;

///
final class GlfwApplication : UEApplication
{
    version(EnableSteam)
    SteamAccess steam;

	private GlfwWindow _mainWindow;
	UEEventsSystem events;
	UEEntity rootEntity;
    private GLFWJoysticks joysticks;

    private double lastMousePosX = 0;
    private double lastMousePosY = 0;

    version(UEProfiling)
    {
        DespikerSender sender;
    }

    ///
    public UEWindow mainWindow() nothrow { return _mainWindow; }

	/// contains the game loop is run in main function
	public int run()
	{
        version(EnableSteam)
        {
            steam = new SteamAccess();
        }

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

        _mainWindow = new GlfwWindow();

		if(!_mainWindow.create(ue.windowSettings.size,ue.windowSettings.title))
			return -1;

		scope(exit) _mainWindow.destroy();
			
		DerelictGL3.reload();

		startEngine();

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glDisable(GL_DEPTH_TEST);

        version(none)
        {
            import core.memory:GC;
            GC.disable();
        }

		while (!_mainWindow.shouldClose)
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
                    
                    import unecht.core.fibers:UEFibers;
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
                    version(EnableSteam)
                    steam.update();
                }

                {
                    version(UEProfiling)
                    auto profZone = Zone(profiler, "vertical sync");

                    _mainWindow.swapBuffers();
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
		_mainWindow.close();
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
                        import unecht.core.logger;
                        log.warning("error starting despiker binary");
                    }
                }
            }
        }
    }

    ///
    void openSteamOverlay()
    {
        version(EnableSteam)
        steam.openOverlay();
    }

    ///
    UESize windowSize()
    {
        return _mainWindow.windowSize;
    }
    ///
    UESize framebufferSize()
    {
        return _mainWindow.size;
    }

public: 
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
        ev.mousePosEvent.x = lastMousePosX = x;
        ev.mousePosEvent.y = lastMousePosY = y;

        populateCurrentKeyMods(ev.mousePosEvent.mods);

        events.trigger(ev);
	}

	void glfwOnMouseButton(int button, int action, int mods)
	{
        UEEvent ev;
        ev.eventType = UEEventType.mouseButton;
        ev.mouseButtonEvent.button = button;
        ev.mouseButtonEvent.action = (action == GLFW_PRESS) ? UEEvent.MouseButtonEvent.Action.down : UEEvent.MouseButtonEvent.Action.up;

        //TODO: click detection here instaed of in mouseControls.d
        ev.mouseButtonEvent.pos.x = lastMousePosX;
        ev.mouseButtonEvent.pos.y = lastMousePosY;

        ev.mouseButtonEvent.pos.mods.setFromBitMaskGLFW(mods);

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

        //import unecht.core.logger;
        //log.infof("glfwOnWndSize: %s -> %s",ue.application.mainWindow.windowSize, ev.windowSizeEvent.size);

        _mainWindow.onResize(ev.windowSizeEvent.size);

		events.trigger(ev);
	}

	void glfwOnFramebufferSize(int width, int height)
	{
		UEEvent ev;
		ev.eventType = UEEventType.framebufferSize;
		ev.framebufferSizeEvent.size = UESize(width,height);
		
        //import unecht.core.logger;
        //log.infof("glfwOnFramebufferSize: %s -> %s",ue.application.mainWindow.size, ev.framebufferSizeEvent.size);

        _mainWindow.onFramebufferResize(ev.framebufferSizeEvent.size);

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
        import unecht.core.scenegraph:UEScenegraph;
        import unecht.core.assetDatabase:UEAssetDatabase;

		events = new UEEventsSystem();
		
		ue.events = events;

		ue.scene = new UEScenegraph();

        joysticks.init(events);

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
        mods.set(glfwGetKey(_mainWindow.window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS,
            glfwGetKey(_mainWindow.window, GLFW_KEY_LEFT_CONTROL) == GLFW_PRESS,
            glfwGetKey(_mainWindow.window, GLFW_KEY_LEFT_ALT) == GLFW_PRESS,
            glfwGetKey(_mainWindow.window, GLFW_KEY_LEFT_SUPER) == GLFW_PRESS);
    }
}

private nothrow extern(C) void error_callback(int error, const(char)* description)
{
	try {
        import unecht.core.logger:log;
        import std.conv:to;
        log.errorf("glfw err: %s '%s'", error, to!string(description));
	}
    catch(Throwable){}
}