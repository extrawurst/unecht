module unecht.gl.vertexBufferObject;

import unecht.gl.shader;

import derelict.opengl3.gl3;

import gl3n.linalg;

///
final class GLVertexBufferObject
{
private:
	GLuint vbo;
	GLuint ibo;
	GLuint vao;

public:
	vec3[] vertices;
	uint[] indices;
	GLuint boundToIndex = GLuint.max;
	
	void init()
	{
		glGenVertexArrays(1, &vao);
		
		glGenBuffers(1, &vbo);
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glBufferData(GL_ARRAY_BUFFER, vertices.length * vec3.sizeof, vertices.ptr, GL_STATIC_DRAW);

		glGenBuffers(1, &ibo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * uint.sizeof, indices.ptr, GL_STATIC_DRAW);
		
		checkGLError();
	}

	void bind(GLuint _index)
	{
		assert(boundToIndex == GLuint.max);
		boundToIndex = _index;

		glBindVertexArray(vao);
		glEnableVertexAttribArray(boundToIndex);

		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glVertexAttribPointer(boundToIndex, 3, GL_FLOAT, GL_FALSE, 0, null);

		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
	}

	void unbind()
	{
		assert(boundToIndex != GLuint.max);

		glDisableVertexAttribArray(boundToIndex);

		boundToIndex = GLuint.max;
	}

	void renderIndexed()
	{
		glDrawElements(GL_TRIANGLES, cast(int)indices.length, GL_UNSIGNED_INT, null);
		
		checkGLError();
	}
}

static void checkGLError()
{
	int i;
	while(true)
	{
		auto err = glGetError();
		
		import std.stdio;
		if(err != GL_NO_ERROR)
			writefln("Error: gl err [%s]: '%s'", i, getGLErrorAsString(err));
		else
			break;
		
		i++;
	}
}

private static string getGLErrorAsString(int _err)
{
	switch(_err)
	{
		case GL_INVALID_ENUM:
			return "GL_INVALID_ENUM";
		case GL_INVALID_VALUE:
			return "GL_INVALID_VALUE";
		case GL_INVALID_OPERATION:
			return "GL_INVALID_OPERATION";
		case GL_INVALID_FRAMEBUFFER_OPERATION:
			return "GL_INVALID_FRAMEBUFFER_OPERATION";
		case GL_OUT_OF_MEMORY:
			return "GL_OUT_OF_MEMORY";
		default:
			return "";
	}
}