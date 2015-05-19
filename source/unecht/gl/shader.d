module unecht.gl.shader;

import derelict.opengl3.gl3;

import gl3n.linalg;

import unecht.gl.vertexBufferObject:checkGLError;

import unecht.meta.misc;

///
enum ShaderType
{
	vertex,
	fragment
}

///
final class GLShader
{
	GLuint shader;
	ShaderType shaderType;
	string errors;
	bool success;

	void create(ShaderType _type, string _src)
	{
		shaderType = _type;

		shader = glCreateShader(shaderType==ShaderType.vertex ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER);

        int stringLength = cast(int)_src.length;
        const(char)* strPtr = _src.ptr;
		glShaderSource(shader, 1, &strPtr, &stringLength);

		glCompileShader(shader);

		GLint success;
		glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
		if (!success) {
			GLchar[1024] InfoLog;
			GLsizei logLen;
			glGetShaderInfoLog(shader, 1024, &logLen, InfoLog.ptr);

			import std.conv:to;
			errors = to!string(InfoLog[0..logLen-1]);

			import std.stdio;
			writefln("Error compiling shader: '%s'", errors);
		}
	}

	///
	void destroy()
	{
		glDeleteShader(shader);
		success = false;
		errors = null;
	}
}
