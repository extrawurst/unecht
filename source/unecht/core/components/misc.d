module unecht.core.components.misc;

import unecht.core.component;
import unecht.core.components.camera;

import unecht.gl.vertexBuffer;
import unecht.gl.shader;
import derelict.opengl3.gl3;

/// 
final class UEMesh : UEComponent
{
	mixin(UERegisterComponent!());

	GLVertexBuffer vertexBuffer;
}

/// 
final class UEMaterial : UEComponent
{
	mixin(UERegisterComponent!());

	//GLProgram program;
	bool polygonFill = true;

	void preRender()
	{
		glPolygonMode( GL_FRONT_AND_BACK, polygonFill ? GL_FILL : GL_LINE );
	}

	void postRender()
	{
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

		mesh.vertexBuffer.render(mat);

		if(material)
			material.postRender();
	}
}