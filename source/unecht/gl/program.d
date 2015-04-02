module unecht.gl.program;

import gl3n.linalg;

import derelict.opengl3.gl3;

import unecht.meta.misc;

import unecht.gl.shader;

///
enum GLAtrribTypes
{
    position,
    normal,
    color,
    texcoord
}

///
final class GLProgram
{
    GLuint program;
    GLint[string] uniforms;
    private string _name;
    
    GLuint[EnumMemberCount!GLAtrribTypes] attribLocations;
    
    void create(GLShader _vshader, GLShader _fshader, string _name="<unknown>")
    {
        this._name = _name;
        
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
            writefln("Error: linking program: '%s': %s", _name, to!string(log[0..logLen-1]));
            return;
        }
        
        foreach(i, att; __traits(allMembers, GLAtrribTypes))
        {
            import std.string:toStringz;
            auto attrName = att.stringof[1..$-1];
            attribLocations[i] = glGetAttribLocation(program, toStringz(attrName));
        }
    }
    
    //TODO:
    void destroy()
    {
        
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
            //TODO: implement a logging scheme
            //writefln("Error: could not locate uniform: '%s' in '%s'", _name, this._name);
            return -1;
        }
    }
    
    ///
    void setUniformVec3(string _name, in vec3 _val)
    {
        auto locPtr = _name in uniforms;
        GLint loc;
        
        if(!locPtr)
            loc = addUniform(_name);
        else
            loc = *locPtr;
        
        glUniform3fv(loc, 1, _val.vector.ptr);
    }
    
    ///
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