module unecht.glfw.glfwwindow;

import std.stdio;

import derelict.glfw3.glfw3;

import unecht.ue;
import unecht.core.types;
import unecht.core.window;

///
class GlfwWindow : UEWindow
{
	/// framebuffer size
	UESize size;
	/// actual window size
	UESize _windowSize;

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
	bool create(UESize _size, string _title)
	{
		import std.string:toStringz;

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
	void onFramebufferResize(UESize size)
	{
		this.size = size;
	}

private:
	GLFWwindow* glfwWindow;
}

private nothrow extern(C) 
{
	void character_callback(GLFWwindow* window, uint codepoint)
	{
		try ue.application.glfwOnChar(codepoint);
		catch(Throwable){}
	}

	void cursor_pos_callback(GLFWwindow* window, double xpos, double ypos)
	{
		try ue.application.glfwOnMouseMove(xpos, ypos);
		catch(Throwable){}
	}

	void mouse_button_callback(GLFWwindow* window, int button, int action, int mods)
	{
		try ue.application.glfwOnMouseButton(button, action, mods);
		catch(Throwable){}
	}

    void mouse_scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
    {
        try ue.application.glfwOnMouseScroll(xoffset, yoffset);
        catch(Throwable){}
    }

	void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
	{
		try ue.application.glfwOnKey(key,scancode,action,mods);
		catch(Throwable){}
	}

	void wnd_size_callback(GLFWwindow* window, int width, int height) nothrow
	{
		try ue.application.glfwOnWndSize(width,height);
		catch(Throwable){}
	}

	void framebuffer_size_callback(GLFWwindow* window, int width, int height)
	{
		try ue.application.glfwOnFramebufferSize(width,height);
		catch(Throwable){}
	}

	void window_focus_callback(GLFWwindow* window, int gainedFocus)
	{
		try ue.application.glfwOnWindowFocus(gainedFocus!=0);
		catch(Throwable){}
	}
}