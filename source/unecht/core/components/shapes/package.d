module unecht.core.components.shapes;

import unecht.core.component;
import unecht.core.components.material;
import unecht.core.components.renderer;
import unecht.core.components.misc;
import unecht.core.defaultInspector;

import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;
import unecht.gl.texture;

import gl3n.linalg;

///
final class UEShapeBox : UEComponent {
    
    mixin(UERegisterObject!());

    @Serialize private
    {
        UERenderer renderer;
        UEMesh mesh;
        UEMaterial material;
    }

    override void onCreate() {
        super.onCreate;

        if(!renderer)
        {
            renderer = this.entity.getComponent!UERenderer;
            if(!renderer)
                renderer = this.entity.addComponent!UERenderer;
        }

        if(!mesh)
        {
            mesh = this.entity.getComponent!UEMesh;
            if(!mesh)
            {
                mesh = this.entity.addComponent!UEMesh;
            }
        }

        if(!material)
        {
            material = this.entity.getComponent!UEMaterial;
            if(!material)
            {
                material = this.entity.addComponent!UEMaterial;
                material.setProgram(UEMaterial.vs_shaded,UEMaterial.fs_shaded, "shaded");
            }
        }

        renderer.mesh = mesh;
        renderer.material = material;
        
        mesh.vertexArrayObject = new GLVertexArrayObject();
        mesh.vertexArrayObject.bind();
        scope(exit) mesh.vertexArrayObject.unbind();
        
        auto upLF = vec3(-1,1,-1);
        auto upLB = vec3(-1,1,1);
        auto upRB = vec3(1,1,1);
        auto upRF = vec3(1,1,-1);
        
        auto dnLF = vec3(-1,-1,-1);
        auto dnLB = vec3(-1,-1,1);
        auto dnRB = vec3(1,-1,1);
        auto dnRF = vec3(1,-1,-1);

        mesh.setVertexData([
                //top
                upLF,upLB,upRB,upRF,
                //front
                upLF,upRF,dnLF,dnRF,
                //bottom
                dnLF,dnRF,dnLB,dnRB,
                //left
                upLF,upLB,dnLF,dnLB,
                //back
                upRB,upLB,dnRB,dnLB,
                //right
                upRB,upRF,dnRB,dnRF
            ]);
        
        auto ul = vec2(0,0);
        auto ur = vec2(1,0);
        auto lr = vec2(1,1);
        auto ll = vec2(0,1);
        
        mesh.uvBuffer = new GLVertexBufferObject([
                //top
                ul,ur,lr,ll,
                //front
                ul,ur,ll,lr,
                //bottom
                ul,ur,ll,lr,
                //left
                ul,ur,ll,lr,
                //back
                ul,ur,ll,lr,
                //right
                ul,ur,ll,lr,
            ]);
        
        mesh.normalBuffer = new GLVertexBufferObject([
                // top
                vec3(0,1,0),vec3(0,1,0),vec3(0,1,0),vec3(0,1,0),
                // front
                vec3(0,0,-1),vec3(0,0,-1),vec3(0,0,-1),vec3(0,0,-1),
                // bottom
                vec3(0,-1,0),vec3(0,-1,0),vec3(0,-1,0),vec3(0,-1,0),
                // left
                vec3(-1,0,0),vec3(-1,0,0),vec3(-1,0,0),vec3(-1,0,0),
                // back
                vec3(0,0,1),vec3(0,0,1),vec3(0,0,1),vec3(0,0,1),
                // right
                vec3(1,0,0),vec3(1,0,0),vec3(1,0,0),vec3(1,0,0)
            ]);
        
        mesh.indexBuffer = new GLVertexBufferObject([
                //top
                0,1,2, 
                0,2,3,
                //front
                4,5,6,
                5,7,6,
                //bottom
                8,9,10,
                9,11,10,
                //left
                12,14,13, 13,14,15,
                //back
                16,17,18, 17,19,18,
                //right
                20,22,21, 21,22,23
            ]);
    }
}

///
final class UEShapeSphere : UEComponent {
    
    mixin(UERegisterObject!());

    UERenderer renderer;
    
    override void onCreate() {
        super.onCreate;      

        renderer = this.entity.getComponent!UERenderer;
        if(!renderer)
            renderer = this.entity.addComponent!UERenderer;
            
        auto mesh = this.entity.getComponent!UEMesh;
        if(!mesh)
            mesh = this.entity.addComponent!UEMesh;

        auto material = this.entity.getComponent!UEMaterial;
        if(!material)
            material = this.entity.addComponent!UEMaterial;

        renderer.material = material;

        material.setProgram(UEMaterial.vs_shaded,UEMaterial.fs_shaded, "shaded");
        renderer.mesh = mesh;
        
        mesh.vertexArrayObject = new GLVertexArrayObject();
        mesh.vertexArrayObject.bind();

        createSphereMesh(mesh,24,24);

        mesh.vertexArrayObject.unbind();
    }

    ///
    override void onDestroy() {
        super.onDestroy;
        
        renderer = null;
    }

    ///
    private void createSphereMesh(UEMesh _mesh, int width, int height)
    {
        import std.math:PI;
        import std.c.math:sinf,cosf;
        
        float theta, phi;
        int t, j, ntri, nvec;
        
        nvec = (height-2)* width+2;
        ntri = (height-2)*(width-1)*2;
        
        auto dat = new vec3[nvec];
        auto idx = new uint[ntri*3];
        auto norm = new vec3[nvec];
        
        for( t=0, j=1; j<height-1; j++ )
        {
            for( int i=0; i<width; i++ )
            {
                theta = (cast(float)j)/(height-1) * PI;
                phi   = (cast(float)i)/(width-1) * PI*2;
                auto x =  sinf(theta) * cosf(phi);
                auto y =  cosf(theta);
                auto z = -sinf(theta) * sinf(phi);

                auto pos = dat[t++] = vec3(x,y,z);

                norm[t-1] = pos.normalized;
            }
        }
        dat[t++] = norm[t-1] = vec3(0,1,0);
        dat[t++] = norm[t-1] = vec3(0,-1,0);
        
        for( t=0, j=0; j<height-3; j++ )
        {
            for( int i=0; i<width-1; i++ )
            {
                idx[t++] = (j  )*width + i  ;
                idx[t++] = (j+1)*width + i+1;
                idx[t++] = (j  )*width + i+1;
                idx[t++] = (j  )*width + i  ;
                idx[t++] = (j+1)*width + i  ;
                idx[t++] = (j+1)*width + i+1;
            }
        }

        for( int i=0; i<width-1; i++ )
        {
            idx[t++] = (height-2)*width;
            idx[t++] = i;
            idx[t++] = i+1;
            idx[t++] = (height-2)*width+1;
            idx[t++] = (height-3)*width + i+1;
            idx[t++] = (height-3)*width + i;
        }

        _mesh.setVertexData(dat);
        _mesh.indexBuffer = new GLVertexBufferObject(idx);
        _mesh.normalBuffer = new GLVertexBufferObject(norm);
    }
}
