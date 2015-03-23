module unecht.gl.vertexBufferObject;

import unecht.gl.shader;

import derelict.opengl3.gl3;

import gl3n.linalg;

///
final class GLVertexBufferObject
{
private:
	GLuint vbo;
	GLuint boundToIndex = GLuint.max;

	int _elementCount;
	int _elementSize;
	uint _elementBufferType;
	ElementType _elementType;

	enum ElementType
	{
		none,
		float_,
	}

public:

	///
	@property int elementSize() const { return _elementSize; }
	///
	@property int elementCount() const { return _elementCount; }

	/// create vertex buffer
	this(vec3[] _vertexData, bool _static=true)
	{
		this.create(_vertexData,false,ElementType.float_,_static);
	}

	/// create uv buffer
	this(vec2[] _uvData, bool _static=true)
	{
		this.create(_uvData,false,ElementType.float_,_static);
	}

	/// create index buffer
	this(uint[] _indexData, bool _static=true)
	{
		this.create(_indexData,true,ElementType.none,_static);
	}

	///
	~this()
	{
		//TODO: ensure teardown
	}

	///
	private void create(T)(T[] _data, bool _elementBuffer, ElementType _elementType, bool _static)
	{
		this._elementBufferType = _elementBuffer?GL_ELEMENT_ARRAY_BUFFER:GL_ARRAY_BUFFER;
		this._elementType = _elementType;
		this._elementCount = cast(int)_data.length;

		glGenBuffers(1, &vbo);
		glBindBuffer(_elementBufferType, vbo);
		glBufferData(_elementBufferType, _data.length * T.sizeof, _data.ptr, GL_STATIC_DRAW);

		if(_elementType != ElementType.none)
		{
			this._elementSize = cast(int)(T.sizeof / float.sizeof);
		}
		
		checkGLError();
	}

	///
	void destroy()
	{
		//TODO: destroy vbo and vao
	}

	///
	void bind(GLuint _index)
	{
		if(_elementType != ElementType.none)
		{
			assert(boundToIndex == GLuint.max);
			boundToIndex = _index;

			glEnableVertexAttribArray(boundToIndex);

			glBindBuffer(_elementBufferType, vbo);
			assert(_elementType == ElementType.float_, "only float supported right now");
			glVertexAttribPointer(boundToIndex, _elementSize, GL_FLOAT, GL_FALSE, 0, null);
		}
		else
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vbo);

		checkGLError();
	}

	///
	void unbind()
	{
		if(_elementType != ElementType.none)
		{
			assert(boundToIndex != GLuint.max);

			glDisableVertexAttribArray(boundToIndex);

			boundToIndex = GLuint.max;
		}

		checkGLError();
	}

	///
	void renderIndexed()
	{
		glDrawElements(GL_TRIANGLES, _elementCount, GL_UNSIGNED_INT, null);
		
		checkGLError();
	}
}

///
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

///
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