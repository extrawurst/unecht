module unecht.appmain;

/// main function starting up the Application class and calls run
version(unittest){}
else:
int main()
{
	import unecht.ue:ue;
	import unecht.glfw.glfwapplication:GlfwApplication;
	import unecht.core.componentManager:UEComponentsManager;

	UEComponentsManager.initComponentManager();
	ue.application = new GlfwApplication();
	return ue.application.run();
}