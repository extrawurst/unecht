module unecht.gl.vertexBuffer;

import unecht.gl.shader;

import derelict.opengl3.gl3;

import gl3n.linalg;

///
final class GLVertexBuffer
{
private:
	GLuint vbo;
	GLuint ibo;
	GLuint vao;
	//TODO: remove shader hardwiring
	GLProgram program;
	GLShader vshader;
	GLShader fshader;
	
	static const string simpleVShader = cast(string)import("simplevs.glsl");
	static const string simpleFShader = cast(string)import("simplefs.glsl");

public:
	vec3[] vertices;
	uint[] indices;
	
	void init()
	{
		vshader = new GLShader();
		fshader = new GLShader();

		vshader.init(ShaderType.vertex, simpleVShader);
		fshader.init(ShaderType.fragment, simpleFShader);
		
		program = new GLProgram();
		program.init(vshader,fshader);

		glGenVertexArrays(1, &vao);
		
		glGenBuffers(1, &vbo);
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glBufferData(GL_ARRAY_BUFFER, vertices.length * vec3.sizeof, vertices.ptr, GL_STATIC_DRAW);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

		glGenBuffers(1, &ibo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * uint.sizeof, indices.ptr, GL_STATIC_DRAW);
		
		checkGLError();
	}
	
	void render(const ref mat4 _mat)
	{
		import std.string:toStringz;
		auto posLoc = glGetAttribLocation(program.program, toStringz("Position"));
		assert(posLoc != -1);
		//import std.stdio;
		//writefln("Debug: attrib location: %s", posLoc);

		glBindVertexArray(vao);
		glEnableVertexAttribArray(posLoc);

		program.validate();
		program.bind();

		program.setUniformMatrix("matWorld", _mat);
		
		glBindBuffer(GL_ARRAY_BUFFER, vbo);
		glVertexAttribPointer(posLoc, 3, GL_FLOAT, GL_FALSE, 0, null);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo);
		glDrawElements(GL_TRIANGLES, cast(int)indices.length, GL_UNSIGNED_INT, null);
		
		program.unbind();
		
		glDisableVertexAttribArray(posLoc);
		
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