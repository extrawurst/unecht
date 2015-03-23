module unecht.core.components.misc;

import unecht;
import unecht.core.component;
import unecht.core.components.camera;

import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;
import unecht.gl.shader;
import derelict.opengl3.gl3;

/// 
final class UEMesh : UEComponent
{
	mixin(UERegisterComponent!());

	GLVertexArrayObject vertexArrayObject;
	GLVertexBufferObject vertexBuffer;
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

	static const string vs_flat = cast(string)import("vs_flat.glsl");
	static const string fs_flat = cast(string)import("fs_flat.glsl");

	GLProgram program;

	bool polygonFill = true;
	bool depthTest = false;

	override void onCreate() {
		super.onCreate;

		program = new GLProgram();

		setProgram(vs_flat,fs_flat, "flat");
	}

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

	void preRender()
	{
		glPolygonMode( GL_FRONT_AND_BACK, polygonFill ? GL_FILL : GL_LINE );

		if(depthTest)
			glEnable(GL_DEPTH_TEST);

		program.bind();
	}

	void postRender()
	{
		program.unbind();

		if(depthTest)
			glDisable(GL_DEPTH_TEST);

		glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
	}
}

/// 
final class UERenderer : UEComponent
{
	mixin(UERegisterComponent!());

	UEMaterial material;
	UEMesh mesh;

	void render(UECamera _cam)
	{
		auto mat = _cam.matProjection * _cam.matLook;

		if(material)
			material.preRender();

		import std.string:toStringz;
		auto posLoc = glGetAttribLocation(material.program.program, toStringz("Position"));
		assert(posLoc != -1);

		//TODO: dont query those things every frame
		auto normLoc = glGetAttribLocation(material.program.program, toStringz("Normal"));
		
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

		mesh.indexBuffer.bind(0);
		scope(exit) mesh.indexBuffer.unbind();

		material.program.validate();
		mesh.indexBuffer.renderIndexed();

		if(normLoc != -1)
			mesh.normalBuffer.unbind();

		if(material)
			material.postRender();
	}
}