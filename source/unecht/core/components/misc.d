module unecht.core.components.misc;

import unecht.core.component;

import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;
import unecht.gl.shader;
import unecht.gl.program;
import unecht.gl.texture;

import gl3n.linalg;
import gl3n.aabb;

/// 
final class UEMesh : UEComponent
{
	mixin(UERegisterObject!());

    @Serialize
    AABB aabb;

	GLVertexArrayObject vertexArrayObject;
	GLVertexBufferObject vertexBuffer;
	GLVertexBufferObject uvBuffer;
	GLVertexBufferObject colorBuffer;
	GLVertexBufferObject indexBuffer;
	GLVertexBufferObject normalBuffer;

    override void onDestroy() {
        super.onDestroy;

        if(vertexArrayObject) vertexArrayObject.destroy();
        if(uvBuffer) uvBuffer.destroy();
        if(colorBuffer) colorBuffer.destroy();
        if(indexBuffer) indexBuffer.destroy();
        if(normalBuffer) normalBuffer.destroy();

        vertexArrayObject   = null;
        vertexBuffer        = null;
        uvBuffer            = null;
        colorBuffer         = null;
        indexBuffer         = null;
        normalBuffer        = null;
    }

    public void setVertexData(vec3[] data)
    {
        aabb = AABB.from_points(data);

        vertexBuffer = new GLVertexBufferObject(data);
    }
}
