module unecht.appmain;

version(unittest){}
else:
int main()
{
	import unecht.ue:ue;
	import unecht.glfw.glfwapplication;
	import unecht.core.componentManager;

	UEComponentsManager.initComponentManager();
	ue.application = new GlfwApplication();
	return ue.application.run();
}