module unecht.core.application;

import unecht.core.types;
import unecht.core.window;

///
interface UEApplication
{
    ///
    int run();
    ///
    void terminate();
    ///
    void openProfiler();
    ///
    void openSteamOverlay();
    ///
    UESize windowSize();
    ///
    UESize framebufferSize();
    ///
    UEWindow mainWindow();

    //TODO: get rid of this hack
    void glfwOnKey(int key, int scancode, int action, int mods);
	void glfwOnMouseMove(double x, double y);
	void glfwOnMouseButton(int button, int action, int mods);
    void glfwOnMouseScroll(double xoffset, double yoffset);
	void glfwOnChar(uint codepoint);
	void glfwOnWndSize(int width, int height);
	void glfwOnFramebufferSize(int width, int height);
	void glfwOnWindowFocus(bool gainedFocus);
}