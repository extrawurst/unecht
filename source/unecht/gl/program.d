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
alias GLProgramAttribLocations = GLuint[EnumMemberCount!GLAtrribTypes];

///
final class GLProgram
{
    GLuint program;
    //TODO: use sorted array here:
    GLint[string] uniforms;
    private string _name;
    
    GLProgramAttribLocations attribLocations;
    
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
            static GLchar[1024] logBuff;
            static GLsizei logLen;
            glGetProgramInfoLog(program, logBuff.sizeof, &logLen, logBuff.ptr);
            import unecht.core.logger;
            import std.conv;
            log.errorf("Error: linking program: '%s': %s", _name, to!string(logBuff[0..logLen-1]));
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
        import unecht.core.logger:log;
        import unecht.gl.vertexBufferObject:checkGLError;
        import std.string:toStringz;
        
        auto loc = glGetUniformLocation(program, toStringz(_name));
        
        checkGLError();
        
        if(loc != -1)
        {
            uniforms[_name] = loc;
            log.infof("Program uniform location found: '%s' at %s", _name, loc);
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

        if(loc != -1)
            glUniform3fv(loc, 1, _val.vector.ptr);
    }

    ///
    void setUniformVec4(string _name, in vec4 _val)
    {
        auto locPtr = _name in uniforms;
        GLint loc;
        
        if(!locPtr)
            loc = addUniform(_name);
        else
            loc = *locPtr;
        
        if(loc != -1)
            glUniform4fv(loc, 1, _val.vector.ptr);
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

        if(loc != -1)
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
            GLchar[1024] logBuff;
            GLsizei logLen;
            glGetProgramInfoLog(program, logBuff.sizeof, &logLen, logBuff.ptr);
            import unecht.core.logger;
            import std.conv;
            log.errorf("Error validating program: '%s'", to!string(logBuff[0..logLen-1]));
        }
    }
    
    void unbind()
    {
        glUseProgram(0);
    }
}