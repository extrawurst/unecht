
import unecht;

void debugRender(double _time)
{
	import derelict.opengl3.gl;
	import derelict.opengl3.deprecatedFunctions;
	import derelict.opengl3.deprecatedConstants;

	float ratio = ue.windowSettings.width / cast(float) ue.windowSettings.height;
	
	glViewport(0, 0, ue.windowSettings.width, ue.windowSettings.height);
	glClear(GL_COLOR_BUFFER_BIT);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(-ratio, ratio, -1.0f, 1.0f, 1.0f, -1.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glRotatef(cast(float) _time * 50.0f, 0.0f, 0.0f, 1.0f);
	glBegin(GL_TRIANGLES);
	glColor3f(1.0f, 0.0f, 0.0f);
	glVertex3f(-0.6f, -0.4f, 0.0f);
	glColor3f(0.0f, 1.0f, 0.0f);
	glVertex3f(0.6f, -0.4f, 0.0f);
	glColor3f(0.0f, 0.0f, 1.0f);
	glVertex3f(0.0f, 0.6f, 0.0f);
	glEnd();
};

shared static this()
{
	ue.debugTick ~= &debugRender;
	ue.windowSettings.width = 640;
	ue.windowSettings.height = 320;
	ue.windowSettings.title = "unecht - hello world sample";
}