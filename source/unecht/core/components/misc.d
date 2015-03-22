module unecht.core.components.misc;

import unecht.core.component;
import unecht.core.components.camera;

import unecht.gl.vertexBuffer;
import unecht.gl.shader;

/// 
final class UEMesh : UEComponent
{
	GLVertexBuffer vertexBuffer;
}

/// 
final class UEMaterial : UEComponent
{
	//GLProgram program;
}

/// 
final class UERenderer : UEComponent
{
	//UEMaterial material;
	UEMesh mesh;

	void render(UECamera _cam)
	{
		auto mat = _cam.matProjection * _cam.matLook;
		mesh.vertexBuffer.render(mat);
	}
}