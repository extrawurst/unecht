module unecht.core.components.misc;

import unecht;
import unecht.core.component;
import unecht.core.components.camera;

import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;
import unecht.gl.shader;
import unecht.gl.texture;
import derelict.opengl3.gl3;

/// 
final class UEMesh : UEComponent
{
	mixin(UERegisterComponent!());

	GLVertexArrayObject vertexArrayObject;
	GLVertexBufferObject vertexBuffer;
	GLVertexBufferObject uvBuffer;
	GLVertexBufferObject colorBuffer;
	GLVertexBufferObject indexBuffer;
	GLVertexBufferObject normalBuffer;
}

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

    private GLProgram program;

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

/// 
final class UERenderer : UEComponent
{
	mixin(UERegisterComponent!());

	UEMaterial material;
	UEMesh mesh;

    version(UEIncludeEditor)static UEMaterial editorMaterial;

	///
	void render(UECamera _cam)
	{
        auto matScale = mat4.scaling(sceneNode.scaling.x,sceneNode.scaling.y,sceneNode.scaling.z);
        auto matModel = mat4.translation(sceneNode.position) * sceneNode.rotation.to_matrix!(4,4) * matScale;

		auto mat = _cam.matProjection * _cam.matLook * matModel;

        version(UEIncludeEditor)
        {
            auto oldMaterial=material;
            if(material && editorMaterial)
                material = editorMaterial;
            scope(exit) material=oldMaterial;
        }

		if(material)
			material.preRender();

		import std.string:toStringz;
        auto posLoc = material.program.attribLocations[GLAtrribTypes.position];
		assert(posLoc != -1);

        auto normLoc = material.program.attribLocations[GLAtrribTypes.normal];
        auto colorLoc = material.program.attribLocations[GLAtrribTypes.color];
        auto uvLoc = material.program.attribLocations[GLAtrribTypes.texcoord];
		
		material.program.setUniformMatrix("matWorld", mat);
		material.program.setUniformVec3("v3ViewDir", _cam.direction);

		mesh.vertexArrayObject.bind();
		scope(exit) mesh.vertexArrayObject.unbind();
		mesh.vertexBuffer.bind(posLoc);
		scope(exit) mesh.vertexBuffer.unbind();

		if(normLoc != -1)
		{
			assert(mesh.normalBuffer, "shader needs Normals but mesh does not contain any");
			mesh.normalBuffer.bind(normLoc);
		}

		if(uvLoc != -1)
		{
			assert(mesh.uvBuffer, "shader needs uvBuffer but mesh does not contain any");
			mesh.uvBuffer.bind(uvLoc);
		}

		if(colorLoc != -1)
		{
			assert(mesh.colorBuffer, "shader needs Normals but mesh does not contain any");
			mesh.colorBuffer.bind(colorLoc);
		}

		mesh.indexBuffer.bind(0);
		scope(exit) mesh.indexBuffer.unbind();

		material.program.validate();
		mesh.indexBuffer.renderIndexed();

		if(normLoc != -1)
			mesh.normalBuffer.unbind();

		if(uvLoc != -1)
			mesh.uvBuffer.unbind();

		if(colorLoc != -1)
			mesh.colorBuffer.unbind();

		if(material)
			material.postRender();
	}
}