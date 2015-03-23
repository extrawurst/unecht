module unecht.gl.shader;

import derelict.opengl3.gl3;

import gl3n.linalg;

import unecht.gl.vertexBufferObject:checkGLError;

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

		auto vsPtr = _src.ptr;
		glShaderSource(shader, 1, &vsPtr, null);

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

///
final class GLProgram
{
	GLuint program;
	GLint[string] uniforms;

	void init(GLShader _vshader, GLShader _fshader)
	{
		program = glCreateProgram();

		glAttachShader(program, _vshader.shader);
		glAttachShader(program, _fshader.shader);

		glLinkProgram(program);

		int success;
		glGetProgramiv(program, GL_LINK_STATUS, &success);
		if (success == 0) {
			GLchar[1024] log;
			GLsizei logLen;
			glGetProgramInfoLog(program, log.sizeof, &logLen, log.ptr);
			import std.stdio;
			import std.conv;
			writefln("Error linking program: '%s'", to!string(log[0..logLen-1]));
		}
	}

	private GLint addUniform(string _name)
	{
		import std.stdio;
		import std.string:toStringz;

		auto loc = glGetUniformLocation(program, toStringz(_name));

		checkGLError();

		if(loc != -1)
		{
			uniforms[_name] = loc;
			writefln("Debug: Program uniform location found: '%s' at %s", _name, loc);
			return loc;
		}
		else
		{
			writefln("Error locating uniform: '%s'", _name);
			return -1;
		}
	}

	void setUniformMatrix(string _name, const ref mat4 _mat)
	{
		auto locPtr = _name in uniforms;
		GLint loc;

		if(!locPtr)
			loc = addUniform(_name);
		else
			loc = *locPtr;

		glUniformMatrix4fv(loc, 1, GL_TRUE, _mat[0].ptr);
	}

	void bind()
	{
		glUseProgram(program);
	}

	void validate()
	{
		glValidateProgram(program);

		GLint success;
		glGetProgramiv(program, GL_VALIDATE_STATUS, &success);
		if (!success) {
			GLchar[1024] log;
			GLsizei logLen;
			glGetProgramInfoLog(program, log.sizeof, &logLen, log.ptr);
			import std.stdio;
			import std.conv;
			writefln("Error validating program: '%s'", to!string(log[0..logLen-1]));
		}
	}

	void unbind()
	{
		glUseProgram(0);
	}
}