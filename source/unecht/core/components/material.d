module unecht.core.components.material;

import derelict.opengl3.gl3;

import gl3n.linalg;

import unecht.core.component;
import unecht.core.assets.texture;

import unecht.gl.shader;
import unecht.gl.program;
import unecht.gl.texture;

///
struct GLMaterialUniforms
{
    private GLProgram _program;

    void setColor(in vec4 _v)
    {
        _program.bind();
        _program.setUniformVec4("globalColor", _v);
    }

    void setMatWorld(const ref mat4 _v)
    {
        _program.bind();
        _program.setUniformMatrix("matWorld", _v);
    }

    void setViewDir(in vec3 _v)
    {
        _program.bind();
        _program.setUniformVec3("v3ViewDir", _v);
    }
}

/// 
final class UEMaterial : UEComponent
{
    mixin(UERegisterObject!());
    
    //TODO: remove shader hardwiring
    static const string vs_shaded = cast(string)import("vs_shaded.glsl");
    static const string fs_shaded = cast(string)import("fs_shaded.glsl");
    
    static const string vs_tex = cast(string)import("vs_tex.glsl");
    static const string fs_tex = cast(string)import("fs_tex.glsl");
    
    static const string vs_flat = cast(string)import("vs_flat.glsl");
    static const string fs_flat = cast(string)import("fs_flat.glsl");
    
    static const string vs_flatcolor = cast(string)import("vs_flatcolor.glsl");
    static const string fs_flatcolor = cast(string)import("fs_flatcolor.glsl");

    ///
    enum CullMode
    {
        cullNone,
        cullFront,
        cullBack
    }

    ///
    @Serialize bool polygonFill = true;
    ///
    @Serialize bool depthTest = true;
    ///
    @Serialize CullMode cullMode = CullMode.cullNone;
    ///
    @Serialize UETexture2D texture;

    ///
    @property GLMaterialUniforms uniforms() { return GLMaterialUniforms(_program); }
    ///
    @property uint attribLocation(GLAtrribTypes _v) const { return _program.attribLocations[_v]; }
    
    ///
    override void onCreate() {
        super.onCreate;

        _program = new GLProgram();

        if(_vshader.length == 0 || _fshader.length == 0 || _shaderName.length == 0)
            setProgram(vs_flat,fs_flat, "flat");
        else
            setProgram(_vshader, _fshader, _shaderName);
    }

    ///
    override void onDestroy() {
        super.onDestroy;
        
        if(_program) _program.destroy();

        _program   = null;
        texture    = null;
    }

    ///
    void setProgram(string _vs, string _fs, string _name)
    {
        import std.typecons:scoped;

        _fshader = _fs;
        _vshader = _vs;
        _shaderName = _name;

        auto vshader = scoped!GLShader();
        auto fshader = scoped!GLShader();
        scope(exit) vshader.destroy();
        scope(exit) fshader.destroy();
        
        vshader.create(ShaderType.vertex, _vshader);
        fshader.create(ShaderType.fragment, _fshader);
        
        _program.create(vshader,fshader, _name);
    }
    
    ///
    void preRender()
    {
        glPolygonMode( GL_FRONT_AND_BACK, polygonFill ? GL_FILL : GL_LINE );
        
        if(depthTest)
        {
            glEnable(GL_DEPTH_TEST);
            glDepthFunc(GL_LEQUAL);
            glDepthMask(GL_TRUE);
        }
        else
            glDisable(GL_DEPTH_TEST);

        if(cullMode != CullMode.cullNone)
        {
            glEnable(GL_CULL_FACE);
            glCullFace((cullMode == CullMode.cullFront) ? GL_FRONT : GL_BACK);
        }
        else
        {
            glDisable(GL_CULL_FACE);
        }
        
        if(texture)
        {
            glActiveTexture(GL_TEXTURE0);
            texture.bind();
        }
        
        _program.bind();
    }
    
    ///
    void postRender()
    {
        _program.unbind();
        
        if(texture)
        {
            glActiveTexture(GL_TEXTURE0);
            texture.unbind();
        }

        if(cullMode != CullMode.cullNone)
            glDisable(GL_CULL_FACE);
        
        glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
    }

    ///
    void validate()
    {
        _program.validate();
    }
    
private:
    GLProgram _program;

    @Serialize
    string _vshader;
    @Serialize
    string _fshader;
    @Serialize
    string _shaderName;
}