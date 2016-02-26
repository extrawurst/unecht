module unecht.core.components.editor.grid;

version(UEIncludeEditor):

import std.array;

import gl3n.linalg;

import unecht.core.component;
import unecht.core.components.material;
import unecht.core.components.misc;
import unecht.core.components.renderer;

import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;

///
final class UEEditorgridComponent : UEComponent {

	mixin(UERegisterObject!());

	override void onCreate() {
		super.onCreate;
		
        import unecht.core.entity;
        entity.layer = UELayer.editor;

		auto renderer = entity.addComponent!UERenderer;
		auto mesh = entity.addComponent!UEMesh;
		
		renderer.mesh = mesh;
		auto material = renderer.material = this.entity.addComponent!UEMaterial;

		mesh.vertexArrayObject = new GLVertexArrayObject();
		mesh.vertexArrayObject.bind();

        enum cellsize = 10;
        enum cnt = 10;
        enum size = cnt*cellsize;
        enum sized2 = size/2;

        auto vertices = appender!(vec3[])();
        vertices.reserve(cnt*cnt);
        foreach(x; 0..cnt)
        {
            foreach(y; 0..cnt)
            {
                vertices.put(vec3(x*cellsize - sized2,0,y*cellsize - sized2));
            }
        }

		mesh.setVertexData(vertices.data);

        auto indices = appender!(uint[])();
        indices.reserve(cnt*cnt*4);
        foreach(x; 0..cnt)
        {
            foreach(y; 0..cnt)
            {
                if(x<cnt-1)
                {
                    indices.put(y*cnt + x);
                    indices.put(y*cnt + x+1);
                }
                if(y<cnt-1)
                {
                    indices.put(y*cnt + x);
                    indices.put((y+1)*cnt + x);
                }
            }
        }

		mesh.indexBuffer = new GLVertexBufferObject(indices.data);
        mesh.indexBuffer.primitiveType = GLRenderPrimitive.lines;
		mesh.vertexArrayObject.unbind();
	}

    override void onUpdate() {
        super.onUpdate;

        //TODO: change size depending on the distance of the editor cam
        //this.sceneNode.scaling = this.sceneNode.scaling*1.1f;
    }
}