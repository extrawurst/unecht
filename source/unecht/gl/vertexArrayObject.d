module unecht.gl.vertexArrayObject;

import derelict.opengl3.gl3;

final class GLVertexArrayObject
{
	private GLuint vao;

	this()
	{
		glGenVertexArrays(1, &vao);
	}

	void bind()
	{
		glBindVertexArray(vao);
	}

	void unbind()
	{
		glBindVertexArray(0);
	}
}