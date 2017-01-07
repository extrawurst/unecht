module unecht.glfw.glfwwindow;

import std.stdio;

import derelict.glfw3.glfw3;

import unecht.ue;
import unecht.core.types;
import unecht.core.window;
import unecht.core.events;

///
class GlfwWindow : UEWindow
{
private:
	/// framebuffer size
	UESize size;
	/// actual window size
	UESize _windowSize;
	///
	UEEvents _events;
	///
	double _lastMousePosX = 0;
	///
    double _lastMousePosY = 0;

package:
	
    ///
    public @property bool isRetina() const { return size.width > _windowSize.width && size.height > _windowSize.height; }
	///
	public @property bool shouldClose() { return glfwWindowShouldClose(glfwWindow)!=0; }
    ///
    public @property GLFWwindow* window() { return glfwWindow; }
	///
	public @property void* windowPtr() { return glfwWindow; }
	///
    public @property UESize windowSize() const { return _windowSize; }
    ///
    public @property UESize framebufferSize() const { return size; }

	///
	bool create(UESize _size, string _title, UEEvents _evs)
	{
		import std.string:toStringz;

		_events = _evs;

        //TODO: support multisampling
        //glfwWindowHint(GLFW_SAMPLES, 4);
		glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, true);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

		glfwWindow = glfwCreateWindow(
			_size.width, 
			_size.height, 
			toStringz(_title), null, null);
		
		if (!glfwWindow)
			return false;

		glfwSetWindowUserPointer(glfwWindow, cast(void*)this);
		glfwMakeContextCurrent(glfwWindow);

        int w,h;
        glfwGetFramebufferSize(glfwWindow, &w, &h);
        size = UESize(w,h);

        glfwGetWindowSize(glfwWindow, &w, &h);
        _windowSize = UESize(w,h);

        //TODO: support for fixed updates befor disabling vsync
		//glfwSwapInterval(0);
        glfwSwapInterval(1);

		glfwSetCursorPosCallback(glfwWindow, &cursor_pos_callback);
		glfwSetMouseButtonCallback(glfwWindow, &mouse_button_callback);
		glfwSetKeyCallback(glfwWindow, &key_callback);
		glfwSetWindowSizeCallback(glfwWindow, &wnd_size_callback);
		glfwSetCharCallback(glfwWindow, &character_callback);
		glfwSetFramebufferSizeCallback(glfwWindow, &framebuffer_size_callback);
		glfwSetWindowFocusCallback(glfwWindow, &window_focus_callback);
        glfwSetScrollCallback(window, &mouse_scroll_callback);
		
		return true;
	}

    ///
    public bool isCursorPosInside(float x, float y) pure const 
    { 
        static immutable border = 1;

        return x > border && 
            y > border && 
            x < _windowSize.width - border && 
            y < _windowSize.height - border; 
    }

    ///
    public void wrapAroundCursorPos(float x, float y)
    {
        static immutable border = 3;

        auto newx = cast(int)x % (_windowSize.width - border);
        auto newy = cast(int)y % (_windowSize.height - border);

        if(x < border)
            newx = _windowSize.width - border + cast(int)x;
        if(y < border)
            newy = _windowSize.height - border + cast(int)y;

        glfwSetCursorPos(glfwWindow, newx, newy);
    }

	///
	void showCursor(bool _show)
	{
		glfwSetInputMode(glfwWindow, GLFW_CURSOR, _show?GLFW_CURSOR_NORMAL:GLFW_CURSOR_HIDDEN);
	}

	///
	void destroy()
	{
		glfwDestroyWindow(glfwWindow);
	}
	
	///
	void close()
	{
		glfwSetWindowShouldClose(glfwWindow, true);
	}
	
	///
	void swapBuffers()
	{
		glfwSwapBuffers(glfwWindow);
	}

	///
	void onResize(UESize size)
	{
		_windowSize = size;
	}

	///
	private void glfwOnKey(int key, int scancode, int action, int mods) nothrow
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

   		_events.trigger(ev);
	}

	///
	private void glfwOnChar(uint codepoint) nothrow
	{
		UEEvent ev;
		ev.eventType = UEEventType.text;
		ev.textEvent.character = cast(dchar)codepoint;

        populateCurrentKeyMods(ev.textEvent.mods);

		_events.trigger(ev);
	}

	///
	private void glfwOnMouseMove(double x, double y) nothrow
	{
        UEEvent ev;
        ev.eventType = UEEventType.mousePos;
        ev.mousePosEvent.x = _lastMousePosX = x;
        ev.mousePosEvent.y = _lastMousePosY = y;

        populateCurrentKeyMods(ev.mousePosEvent.mods);

        _events.trigger(ev);
	}

	///
	private void glfwOnMouseButton(int button, int action, int mods) nothrow
	{
        UEEvent ev;
        ev.eventType = UEEventType.mouseButton;
        ev.mouseButtonEvent.button = button;
        ev.mouseButtonEvent.action = (action == GLFW_PRESS) ? UEEvent.MouseButtonEvent.Action.down : UEEvent.MouseButtonEvent.Action.up;

        //TODO: click detection here instaed of in mouseControls.d
        ev.mouseButtonEvent.pos.x = _lastMousePosX;
        ev.mouseButtonEvent.pos.y = _lastMousePosY;

        ev.mouseButtonEvent.pos.mods.setFromBitMaskGLFW(mods);

        _events.trigger(ev);
	}

	///
    private void glfwOnMouseScroll(double xoffset, double yoffset) nothrow
    {
        UEEvent ev;
        ev.eventType = UEEventType.mouseScroll;
        ev.mouseScrollEvent.xoffset = xoffset;
        ev.mouseScrollEvent.yoffset = yoffset;

        populateCurrentKeyMods(ev.mousePosEvent.mods);

        _events.trigger(ev);
    }

	///
	private void glfwOnWndSize(int width, int height) nothrow
	{
		UEEvent ev;
		ev.eventType = UEEventType.windowSize;
		ev.windowSizeEvent.size = UESize(width,height);

        _windowSize = ev.windowSizeEvent.size;

		_events.trigger(ev);
	}

	///
	private void glfwOnFramebufferSize(int width, int height) nothrow
	{
		UEEvent ev;
		ev.eventType = UEEventType.framebufferSize;
		ev.framebufferSizeEvent.size = UESize(width,height);

		size = ev.framebufferSizeEvent.size;

		_events.trigger(ev);
	}

	///
	private void glfwOnWindowFocus(bool gainedFocus) nothrow
	{
		UEEvent ev;
		ev.eventType = UEEventType.windowFocus;
		ev.focusEvent.gainedFocus = gainedFocus;
		
		_events.trigger(ev);
	}

	///
    private void populateCurrentKeyMods(ref EventModKeys mods) nothrow
    {
		mods.set(glfwGetKey(glfwWindow, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS,
            glfwGetKey(glfwWindow, GLFW_KEY_LEFT_CONTROL) == GLFW_PRESS,
            glfwGetKey(glfwWindow, GLFW_KEY_LEFT_ALT) == GLFW_PRESS,
            glfwGetKey(glfwWindow, GLFW_KEY_LEFT_SUPER) == GLFW_PRESS);
    }

private:
	GLFWwindow* glfwWindow;
}

private nothrow extern(C) 
{
	void character_callback(GLFWwindow* window, uint codepoint)
	{
		GlfwWindow wnd = cast(GlfwWindow)glfwGetWindowUserPointer(window);
		wnd.glfwOnChar(codepoint);
	}

	void cursor_pos_callback(GLFWwindow* window, double xpos, double ypos)
	{
		GlfwWindow wnd = cast(GlfwWindow)glfwGetWindowUserPointer(window);
		wnd.glfwOnMouseMove(xpos, ypos);
	}

	void mouse_button_callback(GLFWwindow* window, int button, int action, int mods)
	{
		GlfwWindow wnd = cast(GlfwWindow)glfwGetWindowUserPointer(window);
		wnd.glfwOnMouseButton(button, action, mods);
	}

    void mouse_scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
    {
		GlfwWindow wnd = cast(GlfwWindow)glfwGetWindowUserPointer(window);
		wnd.glfwOnMouseScroll(xoffset, yoffset);
    }

	void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
	{
		GlfwWindow wnd = cast(GlfwWindow)glfwGetWindowUserPointer(window);
		wnd.glfwOnKey(key,scancode,action,mods);
	}

	void wnd_size_callback(GLFWwindow* window, int width, int height) nothrow
	{
		GlfwWindow wnd = cast(GlfwWindow)glfwGetWindowUserPointer(window);
		wnd.glfwOnWndSize(width,height);
	}

	void framebuffer_size_callback(GLFWwindow* window, int width, int height)
	{
		GlfwWindow wnd = cast(GlfwWindow)glfwGetWindowUserPointer(window);
		wnd.glfwOnFramebufferSize(width,height);
	}

	void window_focus_callback(GLFWwindow* window, int gainedFocus)
	{
		GlfwWindow wnd = cast(GlfwWindow)glfwGetWindowUserPointer(window);
		wnd.glfwOnWindowFocus(gainedFocus!=0);
	}
}