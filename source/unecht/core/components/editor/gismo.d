module unecht.core.components.editor.gismo;

version(UEIncludeEditor):

import unecht.core.component;
import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;

import unecht.core.entity;
import unecht.core.components.renderer;
import unecht.core.components.material;

import gl3n.linalg;

///
final class UEEditorGismo : UEComponent {
    
    mixin(UERegisterComponent!());
    
    override void onCreate() {
        super.onCreate;
        
        import unecht.core.components.misc;
        
        entity.layer = UELayer.editor;
        
        auto renderer = this.entity.addComponent!UERenderer;
        auto mesh = this.entity.addComponent!UEMesh;
        
        renderer.mesh = mesh;
        auto material = renderer.material = this.entity.addComponent!UEMaterial;
        material.setProgram(UEMaterial.vs_flatcolor,UEMaterial.fs_flatcolor, "flat colored");
        material.depthTest = false;
        
        mesh.vertexArrayObject = new GLVertexArrayObject();
        mesh.vertexArrayObject.bind();
        
        enum length = 2;
        mesh.vertexBuffer = new GLVertexBufferObject([
                vec3(0,0,0),
                vec3(length,0,0),
                
                vec3(0,0,0),
                vec3(0,length,0),
                
                vec3(0,0,0),
                vec3(0,0,length),
            ]);
        
        mesh.colorBuffer = new GLVertexBufferObject([
                vec3(1,0,0),
                vec3(1,0,0),
                
                vec3(0,1,0),
                vec3(0,1,0),
                
                vec3(0,0,1),
                vec3(0,0,1),
            ]);
        
        mesh.indexBuffer = new GLVertexBufferObject([0,1, 2,3, 4,5]);
        mesh.indexBuffer.primitiveType = GLRenderPrimitive.lines;
        
        mesh.vertexArrayObject.unbind();
    }
}