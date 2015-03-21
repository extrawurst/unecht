module unecht.core.shader;

import derelict.opengl3.gl3;

import gl3n.linalg;

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

	void init(ShaderType _type, string _src)
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

final class GLProgram
{
	GLuint program;

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
			glGetProgramInfoLog(program, log.sizeof, null, log.ptr);
			import std.stdio;
			import std.conv;
			writefln("Error linking program: '%s'\n", to!string(log));
		}
	}

	void bind()
	{
		glUseProgram(program);
	}

	void validate()
	{
		glValidateProgram(program);
	}

	void unbind()
	{
		glUseProgram(0);
	}
}

final class GLVertexBuffer
{
	vec3[] vertices;
	GLuint vbo;
	GLuint vao;
	GLProgram program;
	GLShader vshader;
	GLShader fshader;

	void init()
	{
		vshader = new GLShader();
		fshader = new GLShader();

		vshader.init(ShaderType.vertex, 
			"#version 150\n"
			"in vec3 Position;\n"
			"void main()\n"
			"{\n"
				"gl_Position = vec4(Position, 1.0);\n"
			"}\n");

		fshader.init(ShaderType.fragment, 
			"#version 150\n"
			"out vec4 Color;\n"
			"void main(void)\n"
			"{\n"
			"    Color = vec4(1.0,1.0,1.0,1.0);\n"
			"}\n");

		program = new GLProgram();
		program.init(vshader,fshader);
		
		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);

		glGenBuffers(1, &vbo);

		glBindBuffer(GL_ARRAY_BUFFER, vbo);

		glBufferData(GL_ARRAY_BUFFER, vertices.sizeof, vertices.ptr, GL_STATIC_DRAW);

		checkGLError();
	}

	void render()
	{
		glEnableVertexAttribArray(0);

		glBindVertexArray(vao);

		program.bind();

		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
		glDrawArrays(GL_POINTS, 0, cast(int)vertices.length);

		program.unbind();

		glDisableVertexAttribArray(0);
		
		checkGLError();
	}

	static void checkGLError()
	{
		int i;
		while(true)
		{
			auto err = glGetError();
			
			import std.stdio;
			if(err != GL_NO_ERROR)
				writefln("gl err [%s]: '%s'", i, getGLErrorAsString(err));
			else
				break;

			i++;
		}
	}

	static string getGLErrorAsString(int _err)
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
}