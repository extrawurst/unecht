module unecht.core.components.renderer;

import gl3n.linalg;

import unecht.core.component;
import unecht.core.components.camera;
import unecht.core.components.material;
import unecht.core.components.misc;

import unecht.gl.program;

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
        
        auto mat = _cam.projectionLook * matModel;
        
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