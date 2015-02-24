module unecht.glfw.window;

import std.stdio;

import derelict.glfw3.glfw3;

import unecht.glfw.window;
import unecht.core.types;

import unecht;

///
struct Window
{
	Size size;
	Pos pos;

package:
	
	///
	@property bool shouldClose() { return glfwWindowShouldClose(glfwWindow)!=0; }
	
	///
	bool create(Size _size, string _title)
	{
		import std.string:toStringz;

		glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, true);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
		glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
		glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
		
		glfwWindow = glfwCreateWindow(
			_size.width, 
			_size.height, 
			toStringz(_title), null, null);
		
		size = _size;
		
		if (!glfwWindow)
			return false;
		
		glfwMakeContextCurrent(glfwWindow);
		glfwSwapInterval(1);
		
		glfwSetKeyCallback(glfwWindow, &key_callback);
		glfwSetWindowSizeCallback(glfwWindow, &wnd_size_callback);
		glfwSetCharCallback(glfwWindow, &character_callback);
		
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

private:

extern(C) void character_callback(GLFWwindow* window, uint codepoint) nothrow
{
	try ue.application.glfwOnChar(codepoint);
	catch{}
}

extern(C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow
{
	try ue.application.glfwOnKey(key,scancode,action,mods);
	catch{}
}

extern(C) void wnd_size_callback(GLFWwindow* window, int width, int height) nothrow
{
	ue.application.mainWindow.size.width = width;
	ue.application.mainWindow.size.height = height;

	try ue.application.glfwOnWndSize();
	catch{}
}