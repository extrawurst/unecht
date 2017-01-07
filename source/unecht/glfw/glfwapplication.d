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

        events = new UEEventsSystem();

        _mainWindow = new GlfwWindow();
        if(!_mainWindow.create(ue.windowSettings.size,ue.windowSettings.title, events))
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
        return _mainWindow.framebufferSize;
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
