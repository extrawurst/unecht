module unecht.core.components.editor;

version(UEIncludeEditor):

import unecht;

import unecht.core.component;
import unecht.core.components.camera;
import unecht.core.components.sceneNode;
import unecht.core.components.misc;
import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;

import derelict.opengl3.gl3;

import imgui;

///
final class UEEditorgridComponent : UEComponent {

	mixin(UERegisterComponent!());

	override void onCreate() {
		super.onCreate;
		
		auto renderer = this.entity.addComponent!UERenderer;
		auto mesh = this.entity.addComponent!UEMesh;
		
		renderer.mesh = mesh;
		renderer.material = this.entity.addComponent!UEMaterial;
		renderer.material.polygonFill = false;

		mesh.vertexArrayObject = new GLVertexArrayObject();
		mesh.vertexArrayObject.bind();

		mesh.vertexBuffer = new GLVertexBufferObject([
				vec3(-10,0,-10),
				vec3(10,0,-10),
				vec3(10,0,10),
				vec3(-10,0,10),
			]);

		mesh.indexBuffer = new GLVertexBufferObject([0,1,2, 0,2,3]);
		mesh.vertexArrayObject.unbind();
	}
}

///
final class UEEditorGismo : UEComponent {
	
	mixin(UERegisterComponent!());
	
	override void onCreate() {
		super.onCreate;
		
		import unecht.core.components.misc;
		
		auto renderer = this.entity.addComponent!UERenderer;
		auto mesh = this.entity.addComponent!UEMesh;
		
		renderer.mesh = mesh;
		renderer.material = this.entity.addComponent!UEMaterial;
		renderer.material.setProgram(UEMaterial.vs_flatcolor,UEMaterial.fs_flatcolor, "flat colored");
		
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
final class UEEditorComponent : UEComponent {

	mixin(UERegisterComponent!());

	override void onCreate() {
		super.onCreate;

		registerEvent(UEEventType.key, &OnKeyEvent);

		entity.addComponent!UEEditorgridComponent;
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

			enum speed = 0.5f;
			
			if(_ev.keyEvent.isModShift)
			{
				if(_ev.keyEvent.key == UEKey.up)
					EditorRootComponent._editorCam.sceneNode.position = EditorRootComponent._editorCam.sceneNode.position + vec3(0,speed,0);
				else if(_ev.keyEvent.key == UEKey.down)
					EditorRootComponent._editorCam.sceneNode.position = EditorRootComponent._editorCam.sceneNode.position + vec3(0,-speed,0);
			}
			else
			{
				if(_ev.keyEvent.key == UEKey.up)
					EditorRootComponent._editorCam.sceneNode.position = EditorRootComponent._editorCam.sceneNode.position + vec3(0,0,speed);
				else if(_ev.keyEvent.key == UEKey.down)
					EditorRootComponent._editorCam.sceneNode.position = EditorRootComponent._editorCam.sceneNode.position + vec3(0,0,-speed);
			}
			
			if(_ev.keyEvent.key == UEKey.left)
				EditorRootComponent._editorCam.sceneNode.position = EditorRootComponent._editorCam.sceneNode.position + vec3(-speed,0,0);
			else if(_ev.keyEvent.key == UEKey.right)
				EditorRootComponent._editorCam.sceneNode.position = EditorRootComponent._editorCam.sceneNode.position + vec3(speed,0,0);
			
			enum rotSpeed = 1.0f;
			if(_ev.keyEvent.key == UEKey.w ||
				_ev.keyEvent.key == UEKey.s)
			{
				bool inc = _ev.keyEvent.key == UEKey.w;
				EditorRootComponent._editorCam.rotation = EditorRootComponent._editorCam.rotation + vec3(rotSpeed * (inc?1.0f:-1.0f),0,0);
			}
			if(_ev.keyEvent.key == UEKey.a ||
				_ev.keyEvent.key == UEKey.d)
			{
				bool inc = _ev.keyEvent.key == UEKey.a;
				EditorRootComponent._editorCam.rotation = EditorRootComponent._editorCam.rotation + vec3(0,rotSpeed * (inc?1.0f:-1.0f),0);
			}
			if(_ev.keyEvent.key == UEKey.q ||
				_ev.keyEvent.key == UEKey.e)
			{
				bool inc = _ev.keyEvent.key == UEKey.q;
				EditorRootComponent._editorCam.rotation = EditorRootComponent._editorCam.rotation + vec3(0,0,rotSpeed * (inc?1.0f:-1.0f));
			}
		}
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

	override void onCreate() {
		super.onCreate;
		
		registerEvent(UEEventType.key, &OnKeyEvent);

		// startup imgui
		{
			import std.file;
			import std.path;
			import std.exception;
			
			string fontPath = thisExePath().dirName().buildPath(".").buildPath("DroidSans.ttf");
			
			enforce(imguiInit(fontPath));
		}

		// hide the whole entity with its hirarchie
		//this.entity.hideInEditor = true;

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
			if(_currentEntity)
			{
				gismo.sceneNode.enabled = true;
				gismo.sceneNode.position = _currentEntity.sceneNode.position;
                gismo.sceneNode.rotation = _currentEntity.sceneNode.rotation;
			}
			else
				gismo.sceneNode.enabled = false;

			_editorCam.render();

            import unecht.core.components.misc;
            UERenderer.editorMaterial = editorMaterial;
            _editorCam.clearBitColor=false;
            _editorCam.render();
            _editorCam.clearBitColor=true;
            UERenderer.editorMaterial = null;
		}

		renderEditorGUI();
	}

	///
	static void renderEditorGUI()
	{
		ubyte mouseButtons = ue.mouseDown?MouseButton.left:0;
		int mouseScroll;

		//TODO: push correct values here
		imguiBeginFrame(cast(int)ue.mousePos.x, ue.application.mainWindow.size.height - cast(int)ue.mousePos.y, mouseButtons, mouseScroll);

		if(_editorVisible)
		{
			renderControlPanel();
			renderScene();
			renderInspector();
			imguiDrawText(0, 2, TextAlign.left, "EditorMode (hide with F1)", RGBA(255, 255, 255));
		}
		else
			imguiDrawText(0, 2, TextAlign.left, "EditorMode (show with F1)", RGBA(255, 255, 255));

		imguiEndFrame();
		imguiRender(ue.application.mainWindow.size.width,ue.application.mainWindow.size.height);
	}

	///
	private static void renderControlPanel()
	{
		static int scroll;
		//TODO: do not use hardcoded values here
		imguiBeginScrollArea("controls: ",
			ue.application.mainWindow.size.width-80,0,
			80,85,&scroll);

		if(imguiButton("play"))
			ue.scene.playing = true;
		if(ue.scene.playing)
		{
			if(imguiButton("stop"))
				ue.scene.playing = false;
		}
		else
		{
			if(imguiButton("step"))
				ue.scene.step;
		}

		imguiEndScrollArea();
	}

	///
	private static void renderScene()
	{
		static int scroll;
		imguiBeginScrollArea("scene",0,0,200,ue.application.mainWindow.size.height,&scroll);

		foreach(n; ue.scene.root.children)
		{
			renderSceneNode(n);
		}

		imguiEndScrollArea();
	}

	///
	private static void renderInspector()
	{
		if(!_currentEntity)
			return;

		static int scroll;
		//TODO: do not use hardcoded values here
		imguiBeginScrollArea("inspector: "~_currentEntity.name,200,0,300,ue.application.mainWindow.size.height,&scroll);

        if(imguiButton("[deselect]"))
        {
            _currentEntity = null;
            return;
        }
		
		foreach(c; _currentEntity.components)
		{
            bool expanded=c.stateInSceneEditor;

            auto subtext = "[  ]";
            if(c.enabled)
                subtext = "[X]";

            imguiCollapse(c.name,subtext,&expanded);

			if(expanded)
            {
                if(imguiButton("toggle"))
                    c.enabled = !c.enabled;

    			import unecht.core.componentManager;
    			if(auto renderer = c.name in UEComponentsManager.editors)
    			{
    				imguiIndent();
    				renderer.render(c);
    				imguiUnindent();
    			}
            }

            c.stateInSceneEditor = expanded;
		}
		
		imguiEndScrollArea();
	}

	///
	private static void renderSceneNode(UESceneNode _node)
	{
		if(_node.entity.hideInEditor)
			return;

        const canExpand = _node.children.length>0;

        if(canExpand)
        {
            bool expanded=_node.sceneNode.stateInSceneEditor;

            if(imguiCollapse(_node.entity.name,"",&expanded))
    		{
    			if(_currentEntity !is _node.entity)
    				_currentEntity = _node.entity;
    		}

            _node.sceneNode.stateInSceneEditor = expanded;

            if(!expanded)
                return;

    		imguiIndent();
    		foreach(n; _node.children)
    		{
    			renderSceneNode(n);
    		}
    		imguiUnindent();
        }
        else
        {
            if(imguiItem(_node.entity.name))
            {
                if(_currentEntity is _node.entity)
                    _currentEntity = null;
                else
                    _currentEntity = _node.entity;
            }
        }
	}
}