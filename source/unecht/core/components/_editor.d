module unecht.core.components._editor;

version(UEIncludeEditor):

import unecht;

import unecht.core.component;
import unecht.core.components.camera;
import unecht.core.components.sceneNode;
import unecht.core.components.material;
import unecht.core.components.misc;
import unecht.core.components.renderer;
import unecht.core.components.internal.gui;

import unecht.core.components.editor.grid;

import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;

import derelict.opengl3.gl3;

///
final class UEEditorGismo : UEComponent {
	
	mixin(UERegisterComponent!());
	
	override void onCreate() {
		super.onCreate;
		
		import unecht.core.components.misc;
		
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

///
final class UEEditorMouseControls : UEComponent
{
    mixin(UERegisterComponent!());

    float speed = 0.1f;

    private bool mouseDown;
    private bool moveMode;
    private vec2 lastMousePos;

    override void onCreate() {
        super.onCreate;

        registerEvent(UEEventType.mouseButton, &onMouseEvent);
        registerEvent(UEEventType.mousePos, &onMouseEvent);
        registerEvent(UEEventType.mouseScroll, &onMouseEvent);
    }

    private void onMouseEvent(UEEvent _ev)
    {
        if(_ev.eventType == UEEventType.mouseButton)
        {
            if(_ev.mouseButtonEvent.button == 0 &&
                !UEGui.capturesMouse)
            {
                mouseDown = _ev.mouseButtonEvent.isDown;
                moveMode = !_ev.mouseButtonEvent.modAlt;
            }
        }
        else if(_ev.eventType == UEEventType.mousePos)
        {
            auto curPos = vec2(_ev.mousePosEvent.x,_ev.mousePosEvent.y);
            auto delta = curPos - lastMousePos;

            if(mouseDown)
            {
                onDrag(delta);
            }

            lastMousePos = curPos;
        }
        else if(_ev.eventType == UEEventType.mouseScroll)
        {
            onDrag(vec2(0), _ev.mouseScrollEvent.yoffset);
        }
    }

    private void onDrag(vec2 delta, double scroll=0)
    {
        //TODO: support shift to speedup
        auto speedNow = speed;

        //TODO: only zoom like this in move mode and move cam in direction of the ray (eye, cursorPosDir-from-screen-to-frustum)
        sceneNode.position = sceneNode.position + (sceneNode.forward * scroll * speedNow);

        if(moveMode)
        {
            sceneNode.position = sceneNode.position + (sceneNode.right * delta.x * -speedNow);
            sceneNode.position = sceneNode.position + (sceneNode.up * delta.y * speedNow);
        }
        else
        {
            sceneNode.angles = sceneNode.angles + vec3(delta.y*speedNow,delta.x*-speedNow,0);
        }
    }
}

///
final class UEEditorNodeKeyControls : UEComponent
{
    mixin(UERegisterComponent!());

    static UESceneNode target;

    override void onUpdate() {
        super.onUpdate;

        enum speed = 0.5f;

        target.position = target.position + (target.up * move.y * speed);
        target.position = target.position + (target.right * move.x * speed);
        target.position = target.position + (target.forward * move.z * speed);

        //target.angles = target.angles + (rotate * speed);
    }

    //TODO: register this by it self once recursive enable/disable works
    ///
    private void OnKeyEvent(UEEvent _ev)
    {
        if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
        {
            if(_ev.keyEvent.isModShift)
            {
                if(_ev.keyEvent.key == UEKey.up)
                    move.y = 1;
                else if(_ev.keyEvent.key == UEKey.down)
                    move.y = -1;
            }
            else
            {
                if(_ev.keyEvent.key == UEKey.up)
                    move.z = 1;
                else if(_ev.keyEvent.key == UEKey.down)
                    move.z = -1;
            }
            
            if(_ev.keyEvent.key == UEKey.left)
                move.x = -1;
            else if(_ev.keyEvent.key == UEKey.right)
                move.x = 1;
           
            if(_ev.keyEvent.key == UEKey.w ||
                _ev.keyEvent.key == UEKey.s)
            {
                bool inc = _ev.keyEvent.key == UEKey.w;
                rotate.x = (inc?1.0f:-1.0f);
            }
            if(_ev.keyEvent.key == UEKey.a ||
                _ev.keyEvent.key == UEKey.d)
            {
                bool inc = _ev.keyEvent.key == UEKey.a;
                rotate.y = (inc?1.0f:-1.0f);
            }
            if(_ev.keyEvent.key == UEKey.q ||
                _ev.keyEvent.key == UEKey.e)
            {
                bool inc = _ev.keyEvent.key == UEKey.q;
                rotate.z = (inc?1.0f:-1.0f);
            }
        }
        else if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Up)
        {

            if(_ev.keyEvent.key == UEKey.up ||
                _ev.keyEvent.key == UEKey.down)
            {
                move.y = 0;
                move.z = 0;
            }

            if(_ev.keyEvent.key == UEKey.left ||
                _ev.keyEvent.key == UEKey.right)
                move.x = 0;

            if(_ev.keyEvent.key == UEKey.w ||
                _ev.keyEvent.key == UEKey.s)
                rotate.x = 0;
            if(_ev.keyEvent.key == UEKey.a ||
                _ev.keyEvent.key == UEKey.d)
                rotate.y = 0;
            if(_ev.keyEvent.key == UEKey.q ||
                _ev.keyEvent.key == UEKey.e)
                rotate.z = 0;
        }
    }

private:
    vec3 move = vec3(0);
    vec3 rotate = vec3(0);
}

///
final class UEEditorComponent : UEComponent {

	mixin(UERegisterComponent!());

    private UEEditorNodeKeyControls keyControls;

	override void onCreate() 
    {
		super.onCreate;

		registerEvent(UEEventType.key, &OnKeyEvent);

		entity.addComponent!UEEditorgridComponent;

        keyControls = entity.addComponent!UEEditorNodeKeyControls;
	}

	///
	private void OnKeyEvent(UEEvent _ev)
	{
		if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Repeat ||
			_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
		{
			if(_ev.keyEvent.key == UEKey.p)
			{
				ue.scene.playing = !ue.scene.playing;
			}
		}

        keyControls.OnKeyEvent(_ev);
	}
}

///
final class UEEditorGUI : UEComponent 
{    
    import derelict.imgui.imgui;

    mixin(UERegisterComponent!());

    void render() {

        {
            ig_SetNextWindowPos(ImVec2(0,ue.application.mainWindow.size.height-25),ImGuiSetCond_Always);

            ig_PushStyleColor(ImGuiCol_WindowBg, ImVec4(1,1,1,0));
            ig_Begin("editor",null,
                ImGuiWindowFlags_AlwaysAutoResize|
                ImGuiWindowFlags_NoTitleBar|
                ImGuiWindowFlags_NoMove);

            scope(exit) 
            { 
                ig_End();
                ig_PopStyleColor();
            }

            if(EditorRootComponent._editorVisible)
                ig_Text("EditorMode (hide with F1)");
            else
                ig_Text("EditorMode (show with F1)");
        }

        if(EditorRootComponent._editorVisible)
        {
            renderControlPanel();
            renderScene();
            renderInspector();
        }
    }

    static float sceneWindowWidth;
    ///
    private static void renderScene()
    {
        ig_SetNextWindowPos(ImVec2(0,0), ImGuiSetCond_Always);

        ig_Begin("scene",null,ImGuiWindowFlags_NoMove);

        foreach(n; ue.scene.root.children)
        {
            renderSceneNode(n);
        }

        sceneWindowWidth = ig_GetWindowWidth();
        ig_End();
    }

    ///
    private static void renderSceneNode(UESceneNode _node)
    {
        if(_node.entity.hideInEditor)
            return;

        const canExpand = _node.children.length>0;

        if(canExpand)
        {
            const expanded = UEGui.TreeNode(cast(void*)(_node.entity), _node.entity.name);

            if(ig_IsItemActive())
            {
                if(EditorRootComponent._currentEntity !is _node.entity)
                    EditorRootComponent.selectEntity(_node.entity);
            }

            if(!expanded)
                return;

            foreach(n; _node.children)
            {
                renderSceneNode(n);
            }

            ig_TreePop();
        }
        else
        {
            ig_Bullet();
            ig_PushIdPtr(cast(void*)(_node.entity));
            auto isSelected = EditorRootComponent._currentEntity is _node.entity;
            if(UEGui.Selectable(_node.entity.name,isSelected))
            {
                if(isSelected)
                    EditorRootComponent.selectEntity(null);
                else
                    EditorRootComponent.selectEntity(_node.entity);
            }
        }
    }

    ///
    private static void renderInspector()
    {
        if(!EditorRootComponent._currentEntity)
            return;

        ig_SetNextWindowPos(ImVec2(sceneWindowWidth,0),ImGuiSetCond_Always);
        bool closed;
        ig_Begin("inspector",&closed,
            ImGuiWindowFlags_AlwaysAutoResize|
            ImGuiWindowFlags_NoCollapse|
            ImGuiWindowFlags_NoMove|
            ImGuiWindowFlags_NoResize);

        scope(exit)ig_End();

        if(closed)
        {
            EditorRootComponent.selectEntity(null);
            return;
        }

        string name = EditorRootComponent._currentEntity.name;
        UEGui.InputText("name",name);
        EditorRootComponent._currentEntity.name = name;

        foreach(int i, c; EditorRootComponent._currentEntity.components)
        {
            auto subtext = " ";
            if(c.enabled)
                subtext = "X";

            ig_PushIdInt(i);
            if(UEGui.TreeNode(c.name))
            {
                ig_SameLine();
                if(UEGui.SmallButton(subtext))
                    c.enabled = !c.enabled;

                import unecht.core.componentManager;
                if(auto renderer = c.name in UEComponentsManager.editors)
                {
                    renderer.render(c);
                }

                ig_TreePop();
            }
            else
            {
                ig_SameLine();
                if(UEGui.SmallButton(subtext))
                    c.enabled = !c.enabled;
            }
        }
    }

    ///
    private static void renderControlPanel()
    {
        static float w=100;
        ig_SetNextWindowPos(ImVec2(ue.application.mainWindow.size.width-w,0),ImGuiSetCond_Always);

        ig_Begin("controls",null,
            ImGuiWindowFlags_NoTitleBar|
            ImGuiWindowFlags_AlwaysAutoResize|
            ImGuiWindowFlags_NoResize|
            ImGuiWindowFlags_NoMove);

        if(ig_Button("play"))
            ue.scene.playing = true;

        if(ue.scene.playing)
        {
            if(ig_Button("stop"))
                ue.scene.playing = false;
        }
        else
        {
            if(ig_Button("step"))
                ue.scene.step;
        }

        w = ig_GetWindowWidth();
        ig_End();
    }
}

///
final class EditorRootComponent : UEComponent {

	mixin(UERegisterComponent!());

	private UEEntity editorComponent;

	private static UEEntity gismo;
    private static UEMaterial editorMaterial;

	private static bool _editorVisible;
	private static UECamera _editorCam;
	private static UEEntity _currentEntity;
    private static UEEditorGUI _editorGUI;

	override void onCreate() {
		super.onCreate;
		
		registerEvent(UEEventType.key, &OnKeyEvent);

		// hide the whole entity with its hirarchie
		//this.entity.hideInEditor = true;

        _editorGUI = entity.addComponent!UEEditorGUI;

        entity.addComponent!UEEditorMouseControls;

		_editorCam = entity.addComponent!UECamera;
		_editorCam.clearColor = vec4(0.1,0.1,0.1,1.0);
		_editorCam.sceneNode.position = vec3(0,5,-20);

		editorComponent = UEEntity.create("subeditor");
		editorComponent.sceneNode.parent = this.sceneNode;
		editorComponent.addComponent!UEEditorComponent;
		editorComponent.sceneNode.enabled = false;

		//TODO: support recursive disabling and move it under the editor subcomponent
		gismo = UEEntity.create("editor gismo");
		gismo.sceneNode.parent = this.sceneNode;
		gismo.addComponent!UEEditorGismo;
		gismo.sceneNode.enabled = false;

        editorMaterial = this.entity.addComponent!UEMaterial;
        editorMaterial.setProgram(UEMaterial.vs_flat,UEMaterial.fs_flat, "color");
        editorMaterial.depthTest = false;
        editorMaterial.polygonFill = false;
        editorMaterial.cullMode = UEMaterial.CullMode.cullBack;

        selectEntity(null);
	}

    override void onUpdate() {
        super.onUpdate;

        if(_currentEntity && _currentEntity.destroyed)
            _currentEntity = null;

        if(_currentEntity)
        {
            gismo.sceneNode.enabled = true;
            gismo.sceneNode.position = _currentEntity.sceneNode.position;
            gismo.sceneNode.rotation = _currentEntity.sceneNode.rotation;
        }
        else
            gismo.sceneNode.enabled = false;
    }
    
    ///
    private void OnKeyEvent(UEEvent _ev)
	{
		if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down &&
			_ev.keyEvent.key == UEKey.f1)
		{
			_editorVisible = !_editorVisible;
			editorComponent.sceneNode.enabled = _editorVisible;
		}
	}

	///
	static void renderEditor()
	{
		if(_editorVisible)
		{
			_editorCam.render();

            import unecht.core.components.misc;
            UERenderer.editorMaterial = editorMaterial;
            _editorCam.clearBitColor=false;
            _editorCam.render();
            _editorCam.clearBitColor=true;
            UERenderer.editorMaterial = null;
		}

        _editorGUI.render();
	}

    ///
    private static void selectEntity(UEEntity _entity)
    {
        if(_entity)
        {
            UEEditorNodeKeyControls.target = _entity.sceneNode;
            _currentEntity = _entity;
        }
        else
        {
            _currentEntity = null;
            UEEditorNodeKeyControls.target = _editorCam.sceneNode;
        }
    }
}