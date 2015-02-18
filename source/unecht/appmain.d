module unecht.appmain;

import std.stdio;
import derelict.glfw3.glfw3;

import unecht;

extern(C) void error_callback(int error, const(char)* description) nothrow
{
	try {
		import std.conv;
		writefln("glfw err: %s '%s'", error, to!string(description));
	}
	catch{}
}

extern(C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods) nothrow
{
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
		glfwSetWindowShouldClose(window, true);
}

auto setupGLFW()
{
	import std.string:toStringz;

	GLFWwindow* window;
	glfwSetErrorCallback(&error_callback);
	
	if (!glfwInit())
	{
		return null;
	}
	
	window = glfwCreateWindow(ue.windowSettings.width, ue.windowSettings.height, toStringz(ue.windowSettings.title), null, null);
	
	if (!window)
	{
		glfwTerminate();
		return null;
	}
	
	glfwMakeContextCurrent(window);
	glfwSwapInterval(1);
	glfwSetKeyCallback(window, &key_callback);
	
	return window;
}

int main()
{
	import derelict.opengl3.gl;

	DerelictGL.load();
	DerelictGLFW3.load();
	
	auto window = setupGLFW();
	
	if(window == null)
		return -1;
	
	DerelictGL.reload();
	
	while (!glfwWindowShouldClose(window))
	{
		foreach(f; ue.debugTick)
			f(glfwGetTime());
		
		glfwSwapBuffers(window);
		glfwPollEvents();
	}
	
	glfwDestroyWindow(window);
	glfwTerminate();

	return 0;
}