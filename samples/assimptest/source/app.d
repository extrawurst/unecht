module app;

import unecht;
import derelict.assimp3.assimp;

import std.stdio;

///
@UEDefaultInspector!TestLogic
final class TestLogic : UEComponent
{
    mixin(UERegisterComponent!());

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.key, &OnKeyEvent);

        DerelictASSIMP3.load();

        auto scene = aiImportFile("data/teapot.obj", aiProcess_Triangulate|aiProcess_GenSmoothNormals);
        assert(scene);
        scope(exit) aiReleaseImport(scene);

        auto err = aiGetErrorString();
        writefln("ai err: %s", to!string(err));

        writefln("ai imported: %s", *scene);

        if(scene.mNumMeshes > 0)
        {
            loadMesh(scene.mMeshes[0]);
        }
    }

    private void loadMesh(in aiMesh* aimesh)
    {
        import unecht.core.components.renderer;
        import unecht.core.components.misc;
        import unecht.gl.vertexArrayObject;
        import unecht.gl.vertexBufferObject;

        auto renderer = this.entity.addComponent!UERenderer;
        auto mesh = this.entity.addComponent!UEMesh;
        
        renderer.mesh = mesh;
        
        auto material = this.entity.addComponent!UEMaterial;
        material.setProgram(UEMaterial.vs_shaded,UEMaterial.fs_shaded, "shaded");
        renderer.material = material;

        mesh.vertexArrayObject = new GLVertexArrayObject();
        mesh.vertexArrayObject.bind();
        scope(exit) mesh.vertexArrayObject.unbind();
        
        mesh.vertexBuffer = new GLVertexBufferObject(cast(vec3[])aimesh.mVertices[0..aimesh.mNumVertices]);
        mesh.normalBuffer = new GLVertexBufferObject(cast(vec3[])aimesh.mNormals[0..aimesh.mNumVertices]);

        auto indices = new uint[aimesh.mNumFaces*3];
        foreach (i; 0..aimesh.mNumFaces) {
            auto face = aimesh.mFaces[i];
            assert(face.mNumIndices == 3);
            indices[i*3+0] = face.mIndices[0];
            indices[i*3+1] = face.mIndices[1];
            indices[i*3+2] = face.mIndices[2];
        }

        mesh.indexBuffer = new GLVertexBufferObject(indices);
    }

    void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.key == UEKey.esc)
                ue.application.terminate();
        }
    }

}

shared static this()
{
	ue.windowSettings.size.width = 1024;
	ue.windowSettings.size.height = 768;
	ue.windowSettings.title = "unecht - assimptest";

	ue.hookStartup = () {
		auto newE = UEEntity.create("game");
        newE.addComponent!TestLogic;

		auto newE2 = UEEntity.create("camera entity");
		newE2.sceneNode.position = vec3(0,15,-20);
        newE2.sceneNode.angles = vec3(30,0,0);

        import unecht.core.components.camera;
		auto cam = newE2.addComponent!UECamera;
	};
}