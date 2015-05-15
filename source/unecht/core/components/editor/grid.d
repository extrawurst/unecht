module unecht.core.components.editor.grid;

version(UEIncludeEditor):

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
		
		auto renderer = entity.addComponent!UERenderer;
		auto mesh = entity.addComponent!UEMesh;
		
		renderer.mesh = mesh;
		auto material = renderer.material = this.entity.addComponent!UEMaterial;
		material.polygonFill = false;

		mesh.vertexArrayObject = new GLVertexArrayObject();
		mesh.vertexArrayObject.bind();

        enum size = 100;
		mesh.vertexBuffer = new GLVertexBufferObject([
				vec3(-size,0,-size),
				vec3(size,0,-size),
				vec3(size,0,size),
				vec3(-size,0,size),
			]);

		mesh.indexBuffer = new GLVertexBufferObject([0,1,2, 0,2,3]);
		mesh.vertexArrayObject.unbind();
	}
}