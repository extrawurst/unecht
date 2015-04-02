module unecht.core.components.misc;

import unecht.core.component;

import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;
import unecht.gl.shader;
import unecht.gl.program;
import unecht.gl.texture;

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
