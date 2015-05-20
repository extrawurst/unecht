module unecht.core.components.material;

import derelict.opengl3.gl3;

import gl3n.linalg;

import unecht.core.component;

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

version(UEIncludeEditor)
{
import unecht.core.componentManager;
@EditorInspector("UEMaterial")
static class UEMaterialInspector : IComponentEditor
{
    override void render(UEComponent _component)
    {
        import derelict.imgui.imgui;
        import unecht.core.components.internal.gui;
        import std.format;

        auto thisT = cast(UEMaterial)_component;

        static immutable TEX_SIZE = 100;

        ig_Checkbox("polygonFill",&thisT.polygonFill);
        ig_Checkbox("depthTest",&thisT.depthTest);
        UEGui.EnumCombo("cull",thisT.cullMode);
        UEGui.Text("shader: "~thisT._shaderName);
        UEGui.Text("texture:");
        if(thisT._tex)
            ig_Image(cast(void*)thisT._tex.tex,ImVec2(TEX_SIZE,TEX_SIZE));
        else
            UEGui.Text("<none>");
    }
   
    mixin UERegisterInspector!UEMaterialInspector;
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
    
    static const string dummyTex = cast(string)import("rgb.png");

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
    @property void texture(GLTexture _texture) { setTexture(_texture); }
    ///
    @property GLMaterialUniforms uniforms() { return GLMaterialUniforms(_program); }
    ///
    @property uint attribLocation(GLAtrribTypes _v) const { return _program.attribLocations[_v]; }
    
    ///
    override void onCreate() {
        super.onCreate;

        _program = new GLProgram();
        
        _tex = new GLTexture();
        _tex.create(dummyTex);
        _tex.pointFiltering = true;

        if(_vshader.length == 0 || _fshader.length == 0 || _shaderName.length == 0)
            setProgram(vs_flat,fs_flat, "flat");
        else
            setProgram(_vshader, _fshader, _shaderName);
    }

    ///
    override void onDestroy() {
        super.onDestroy;
        
        if(_program) _program.destroy();
        if(_tex) _tex.destroy();

        _program   = null;
        _tex       = null;
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
        
        glActiveTexture(GL_TEXTURE0);
        _tex.bind();
        
        _program.bind();
    }
    
    ///
    void postRender()
    {
        _program.unbind();
        
        glActiveTexture(GL_TEXTURE0);
        _tex.unbind();

        if(cullMode != CullMode.cullNone)
            glDisable(GL_CULL_FACE);
        
        glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
    }

    void validate()
    {
        _program.validate();
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
    GLProgram _program;

    @Serialize
    string _vshader;
    @Serialize
    string _fshader;
    @Serialize
    string _shaderName;
}