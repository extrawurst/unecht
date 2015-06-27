module unecht.glfw.window;

import std.stdio;

import derelict.glfw3.glfw3;

import unecht.glfw.window;
import unecht.core.types;

import unecht;

///
struct UEWindow
{
	/// framebuffer size
	UESize size;
	/// actual window size
	UESize windowSize;
	///
	UEPos pos;

package:
	
    public @property bool isRetina() const { return size.width >= 2048 && size.height >= 1374;}
	///
	@property bool shouldClose() { return glfwWindowShouldClose(glfwWindow)!=0; }
    ///
    public @property GLFWwindow* window() { return glfwWindow; }

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

		windowSize = _size;

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

private:
	GLFWwindow* glfwWindow;
}

private nothrow extern(C) 
{
	void character_callback(GLFWwindow* window, uint codepoint)
	{
		try ue.application.glfwOnChar(codepoint);
		catch{}
	}

	void cursor_pos_callback(GLFWwindow* window, double xpos, double ypos)
	{
		try ue.application.glfwOnMouseMove(xpos, ypos);
		catch{}
	}

	void mouse_button_callback(GLFWwindow* window, int button, int action, int mods)
	{
		try ue.application.glfwOnMouseButton(button, action, mods);
		catch{}
	}

    void mouse_scroll_callback(GLFWwindow* window, double xoffset, double yoffset)
    {
        try ue.application.glfwOnMouseScroll(xoffset, yoffset);
        catch{}
    }

	void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
	{
		try ue.application.glfwOnKey(key,scancode,action,mods);
		catch{}
	}

	void wnd_size_callback(GLFWwindow* window, int width, int height) nothrow
	{
		ue.application.mainWindow.size.width = width;
		ue.application.mainWindow.size.height = height;

		try ue.application.glfwOnWndSize(width,height);
		catch{}
	}

	void framebuffer_size_callback(GLFWwindow* window, int width, int height)
	{
		try ue.application.glfwOnFramebufferSize(width,height);
		catch{}
	}

	void window_focus_callback(GLFWwindow* window, int gainedFocus)
	{
		try ue.application.glfwOnWindowFocus(gainedFocus!=0);
		catch{}
	}
}