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

    @NonSerialize{
	GLVertexArrayObject vertexArrayObject;
	GLVertexBufferObject vertexBuffer;
	GLVertexBufferObject uvBuffer;
	GLVertexBufferObject colorBuffer;
	GLVertexBufferObject indexBuffer;
	GLVertexBufferObject normalBuffer;
    }

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
}
