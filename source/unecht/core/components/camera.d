module unecht.core.components.camera;

import unecht.core.component;
import unecht.core.componentManager;

import unecht.core.types;

import gl3n.linalg;

//TODO: create mixin and automation
version(UEIncludeEditor)
@EditorInspector("UECamera")
static class UECameraInspector : IComponentEditor
{
    override void render(UEComponent _component)
    {
        auto thisT = cast(UECamera)_component;
        
        import imgui;
        import std.format;
        
        imguiLabel(format("rot: %s",thisT.rotation));
        imguiLabel(format("dir: %s",thisT.dir));
        imguiLabel(format("up: %s",thisT.up));
        imguiLabel(format("fov: %s",thisT.fieldOfView));
    }

    mixin(UERegisterInspector!UECameraInspector);
}

//TODO: add properties and make matrix updates implicit
/// 
final class UECamera : UEComponent
{
	mixin(UERegisterComponent!());

	@property auto direction() const { return dir; }

	vec3 rotation = vec3(0,0,0);
	private vec3 dir = vec3(0);
	private vec3 up = vec3(0);

	static const vec3 ORIG_DIR = vec3(0,0,1);
	static const vec3 ORIG_UP = vec3(0,1,0);

	mat4 matProjection = mat4.identity;
	mat4 matLook = mat4.identity;

	float fieldOfView = 60;
	float clipNear = 1;
	float clipFar = 1000;

	vec4 clearColor = vec4(0,0,0,1);
	bool clearBitColor = true;
	bool clearBitDepth = true;

	UERect viewport;

	void updateLook()
	{
		import std.math:PI;

		dir = ORIG_DIR;
		dir = dir * quat.xrotation(rotation.x * (PI/180.0f));
		dir = dir * quat.yrotation(rotation.y * (PI/180.0f));

		up = ORIG_UP;
		up = up * quat.zrotation(rotation.z * (PI/180.0f));
		up = up * quat.xrotation(rotation.x * (PI/180.0f));
		up = up * quat.yrotation(rotation.y * (PI/180.0f));

		auto target = entity.sceneNode.position + dir;

		matLook = mat4.look_at(
			entity.sceneNode.position,
			target,
			up);
	}

	void updateProjection()
	{
		matProjection = mat4.perspective(1024,768,fieldOfView,clipNear,clipFar);
	}

	void render()
	{
		import unecht;
		import derelict.opengl3.gl3;
		import unecht.core.components.misc;

		auto renderers = ue.scene.gatherAllComponents!UERenderer;
		
		updateProjection();
		updateLook();
		
		auto clearBits = 0;
		if(clearBitColor) clearBits |= GL_COLOR_BUFFER_BIT;
		if(clearBitDepth) clearBits |= GL_DEPTH_BUFFER_BIT;
		
		glClearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
		glClear(clearBits);

		UESize viewportSize = UESize(
			cast(int)(viewport.size.x * ue.application.mainWindow.size.width),
			cast(int)(viewport.size.y * ue.application.mainWindow.size.height));
		glViewport(viewport.pos.left,viewport.pos.top,viewportSize.width,viewportSize.height);
		
		foreach(r; renderers)
		{
			if(r.enabled && r.sceneNode.enabled)
				r.render(this);
		}
	}
}