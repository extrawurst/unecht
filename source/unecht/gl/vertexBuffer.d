module unecht.gl.vertexBuffer;

import unecht.gl.shader;

import derelict.opengl3.gl3;

import gl3n.linalg;

///
final class GLVertexBuffer
{
	vec3[] vertices;
	GLuint vbo;
	GLuint vao;
	GLProgram program;
	GLShader vshader;
	GLShader fshader;

	static const string simpleVShader = cast(string)import("simplevs.glsl");
	static const string simpleFShader = cast(string)import("simplefs.glsl");
	
	void init()
	{
		vshader = new GLShader();
		fshader = new GLShader();
		
		vshader.init(ShaderType.vertex, simpleVShader);
		fshader.init(ShaderType.fragment, simpleFShader);
		
		program = new GLProgram();
		program.init(vshader,fshader);

		glGenVertexArrays(1, &vao);
		glBindVertexArray(vao);
		
		glGenBuffers(1, &vbo);
		
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		
		glBufferData(GL_ARRAY_BUFFER, vertices.sizeof, vertices.ptr, GL_STATIC_DRAW);
		
		checkGLError();
	}
	
	void render(const ref mat4 _mat)
	{
		glEnableVertexAttribArray(0);
		
		glBindVertexArray(vao);
		
		program.bind();

		program.setUniformMatrix("matWorld", _mat);
		
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, null);
		glDrawArrays(GL_POINTS, 0, cast(int)vertices.length);
		
		program.unbind();
		
		glDisableVertexAttribArray(0);
		
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