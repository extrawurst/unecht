module unecht.core.shader;

import derelict.opengl3.gl3;

import gl3n;

enum ShaderType
{
	vertex,
	fragment
}

final class GLShader
{
	GLuint shader;
	ShaderType shaderType;
	string errors;
	bool success;

	void init(string _src, ShaderType _type)
	{
		shaderType = _type;

		shader = glCreateShader(shaderType==ShaderType.vertex ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER);

		auto vsPtr = _src.ptr;
		glShaderSource(shader, 1, &vsPtr, null);

		glCompileShader(shader);

		GLint success;
		glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
		if (!success) {
			GLchar[1024] InfoLog;
			glGetShaderInfoLog(shader, 1024, null, InfoLog.ptr);

			import std.conv:to;
			errors = to!string(InfoLog);

			import std.stdio;
			writefln("Error compiling shader: '%s'", errors);
		}
	}
}

final class GLVertexBuffer
{
	vec3[] vertices;
	GLuint vbo;

	void init()
	{
		glGenBuffers(1, &vbo);

		glBindBuffer(GL_ARRAY_BUFFER, vbo);

		glBufferData(GL_ARRAY_BUFFER, vertices.sizeof, vertices.ptr, GL_STATIC_DRAW);
	}

	void render()
	{
		glEnableVertexAttribArray(0);

		glBindBuffer(vbo);
		glVertexAttribPointer(0, vertices.length * 3, GL_FLOAT, GL_FALSE, 0, 0);
		glDrawArrays(GL_POINTS, 0, vertices.length);

		glDisableVertexAttribArray(0);
	}
}