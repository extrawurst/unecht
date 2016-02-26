module unecht.core.components.renderer;

import unecht.core.component;
import unecht.core.components.camera;
import unecht.core.components.material;
import unecht.core.components.misc;
import unecht.core.defaultInspector;

import unecht.gl.program;

import gl3n.linalg;

/// 
@UEDefaultInspector!UERenderer
final class UERenderer : UEComponent
{
private:
    //@Serialize
    UEMaterial _material;

public:
    mixin(UERegisterObject!());

    //@Serialize
    UEMesh mesh;

    version(UEIncludeEditor)static UEMaterial editorMaterial;

    ///
    @property UEMaterial material(UEMaterial _v) { setMaterial(_v); return _v; }
    ///
    @property UEMaterial material() { return _material; }

    ///
    void render(UECamera _cam)
    {
        if(!mesh)
            return;

        auto matScale = mat4.scaling(sceneNode.scaling.x,sceneNode.scaling.y,sceneNode.scaling.z);
        auto matModel = mat4.translation(sceneNode.position) * sceneNode.rotation.to_matrix!(4,4) * matScale;
        
        auto mat = _cam.projectionLook * matModel;
        
        version(UEIncludeEditor)
        {
            auto oldMaterial=_material;
            if(_material && editorMaterial)
                _material = editorMaterial;
            scope(exit) _material=oldMaterial;
        }
        
        if(_material)
            _material.preRender();
        scope(exit)
        {
            if(_material)
                _material.postRender();
        }
        
        auto posLoc = _material.attribLocation(GLAtrribTypes.position);
        auto normLoc = _material.attribLocation(GLAtrribTypes.normal);
        auto colorLoc = _material.attribLocation(GLAtrribTypes.color);
        auto uvLoc = _material.attribLocation(GLAtrribTypes.texcoord);

        _material.uniforms.setMatWorld(mat);
        _material.uniforms.setViewDir(_cam.sceneNode.forward);

        if(!mesh.vertexArrayObject)
            return;

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

        scope(exit)
        {
            if(normLoc != -1)
                mesh.normalBuffer.unbind();
            
            if(uvLoc != -1)
                mesh.uvBuffer.unbind();
            
            if(colorLoc != -1)
                mesh.colorBuffer.unbind();
        }
        
        mesh.indexBuffer.bind(0);
        scope(exit) mesh.indexBuffer.unbind();

        material.validate();
        mesh.indexBuffer.renderIndexed();
    }

    private void setMaterial(UEMaterial _v)
    {
        _material = _v;
    }
}