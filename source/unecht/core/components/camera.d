module unecht.core.components.camera;

import unecht.core.components.misc;
import unecht.core.components.renderer;
import unecht.core.component;
import unecht.core.object;
import unecht.core.componentManager;
import unecht.core.entity;

import unecht.core.types;

import gl3n.linalg;

//TODO: create mixin and automation
version(UEIncludeEditor)
@EditorInspector("UECamera")
static class UECameraInspector : IComponentEditor
{
    override void render(UEObject _component)
    {
        auto thisT = cast(UECamera)_component;
        
        import derelict.imgui.imgui;
        import unecht.core.components.internal.gui;
        import std.format;

        ig_ColorEdit4("clearColor",thisT.clearColor.vector,true);
        UEGui.DragFloat("fov",thisT.fieldOfView,1,360);
        UEGui.DragFloat("near",thisT.clipNear,0.01f);
        UEGui.DragFloat("far",thisT.clipFar,0.01f);

        ig_Checkbox("isOrthographic",&thisT.isOrthographic);
        if(thisT.isOrthographic)
        {
            UEGui.DragFloat("orthoSize",thisT.orthoSize,0.01f);
        }
    }

    mixin UERegisterInspector!UECameraInspector;
}

//TODO: add properties and make matrix updates implicit
/// 
final class UECamera : UEComponent
{
	mixin(UERegisterObject!());

    ///
    @property auto projectionLook() const { return matProjection * matLook; }

    @Serialize{
        float fieldOfView = 60;
        float clipNear = 1;
        float clipFar = 1000;
        
        vec4 clearColor = vec4(0,0,0,1);
        bool clearBitColor = true;
        bool clearBitDepth = true;
        int visibleLayers = UECameraDefaultLayers;
        
        bool isOrthographic=false;
        float orthoSize=1;
        
        UERect viewport;
    }

	void updateLook()
	{
        auto lookat = entity.sceneNode.position + entity.sceneNode.forward;

        matLook = mat4.look_at(entity.sceneNode.position,lookat,entity.sceneNode.up);
	}

	void updateProjection()
	{
        if(!isOrthographic)
		{
			import unecht;
			auto w = ue.application.mainWindow.size.width;
			auto h = ue.application.mainWindow.size.height;
		    matProjection = mat4.perspective(w, h, fieldOfView, clipNear, clipFar);
		}
        else
        {
            matProjection = mat4.orthographic(-(orthoSize/2),(orthoSize/2),-(orthoSize/2),(orthoSize/2),clipNear,clipFar);
        }
	}

	void render()
	{
        import unecht;
        import derelict.opengl3.gl3;

		auto renderers = ue.scene.gatherAllComponents!UERenderer;
		
		updateProjection();
		updateLook();
		
		int clearBits = 0;
		if(clearBitColor) clearBits |= GL_COLOR_BUFFER_BIT;
		if(clearBitDepth) clearBits |= GL_DEPTH_BUFFER_BIT;
		
        if(clearBits!=0)
        {
    		glClearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
    		glClear(clearBits);
        }

		UESize viewportSize = UESize(
			cast(int)(viewport.size.x * ue.application.mainWindow.size.width),
			cast(int)(viewport.size.y * ue.application.mainWindow.size.height));
		glViewport(viewport.pos.left,viewport.pos.top,viewportSize.width,viewportSize.height);
		
		foreach(r; renderers)
		{
			if(r.enabled && r.sceneNode.enabled)
            {
                import unecht.core.stdex;
                if(testBit(visibleLayers, r.entity.layer))
				    r.render(this);
            }
		}
	}

private:
    mat4 matProjection = mat4.identity;
    mat4 matLook = mat4.identity;
}