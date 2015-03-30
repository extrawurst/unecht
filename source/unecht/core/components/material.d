module unecht.core.components.material;

public import std.typecons:scoped;

import derelict.opengl3.gl3;

import unecht.core.component;

import unecht.gl.shader;
import unecht.gl.texture;

/// 
final class UEMaterial : UEComponent
{
    mixin(UERegisterComponent!());
    
    //TODO: remove shader hardwiring
    static const string vs_shaded = cast(string)import("vs_shaded.glsl");
    static const string fs_shaded = cast(string)import("fs_shaded.glsl");
    
    static const string vs_tex = cast(string)import("vs_tex.glsl");
    static const string fs_tex = cast(string)import("fs_tex.glsl");
    
    static const string vs_flat = cast(string)import("vs_flat.glsl");
    static const string fs_flat = cast(string)import("fs_flat.glsl");
    
    static const string vs_flatcolor = cast(string)import("vs_flatcolor.glsl");
    static const string fs_flatcolor = cast(string)import("fs_flatcolor.glsl");
    
    static const string dummyTex = cast(string)import("rgb.png");
    
    package GLProgram program;
    
    bool polygonFill = true;
    bool depthTest = false;
    
    @property void texture(GLTexture _texture) { setTexture(_texture); }
    
    ///
    override void onCreate() {
        super.onCreate;
        
        program = new GLProgram();
        
        _tex = new GLTexture();
        _tex.create(dummyTex);
        _tex.pointFiltering = true;
        
        setProgram(vs_flat,fs_flat, "flat");
    }
    
    ///
    void setProgram(string _vs, string _fs, string _name)
    {
        auto vshader = scoped!GLShader();
        auto fshader = scoped!GLShader();
        scope(exit) vshader.destroy();
        scope(exit) fshader.destroy();
        
        vshader.create(ShaderType.vertex, _vs);
        fshader.create(ShaderType.fragment, _fs);
        
        program.create(vshader,fshader, _name);
    }
    
    ///
    void preRender()
    {
        glPolygonMode( GL_FRONT_AND_BACK, polygonFill ? GL_FILL : GL_LINE );
        
        if(depthTest)
            glEnable(GL_DEPTH_TEST);
        else
            glDisable(GL_DEPTH_TEST);
        
        glActiveTexture(GL_TEXTURE0);
        _tex.bind();
        
        program.bind();
    }
    
    ///
    void postRender()
    {
        program.unbind();
        
        glActiveTexture(GL_TEXTURE0);
        _tex.unbind();
        
        glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
    }
    
protected:
    
    ///
    void setTexture(GLTexture _texture)
    {
        if(_tex)
            _tex.destroy();
        
        _tex = _texture;
    }
    
private:
    GLTexture _tex;
}