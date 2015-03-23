module unecht.core.components.editor;

import unecht;

import unecht.core.component;
import unecht.core.components.camera;
import unecht.gl.vertexBuffer;

import derelict.opengl3.gl3;

import imgui;

///
final class UEEditorgridComponent : UEComponent {

	override void onCreate() {
		super.onCreate;

		import unecht.core.components.misc;
		import unecht.gl.vertexBuffer;
		
		auto renderer = this.entity.addComponent!UERenderer;
		auto mesh = this.entity.addComponent!UEMesh;
		
		renderer.mesh = mesh;
		renderer.material = new UEMaterial();
		renderer.material.polygonFill = false;
		
		mesh.vertexBuffer = new GLVertexBuffer();
		mesh.vertexBuffer.vertices = [
			vec3(-10,0,-10),
			vec3(10,0,-10),
			vec3(10,0,10),
			vec3(-10,0,10),
		];
		mesh.vertexBuffer.indices = [0,1,2, 0,2,3];
		mesh.vertexBuffer.init();
	}
}

///
final class EditorComponent : UEComponent {

	private static bool _editorVisible;
	//private static GLVertexBuffer gismo;
	private static UECamera _editorCam;
	
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
		this.entity.hideInEditor = true;

		_editorCam = entity.addComponent!UECamera;
		_editorCam.sceneNode.position = vec3(0,500,0);
		_editorCam.dir = vec3(0,-1,-0.01);

		entity.addComponent!UEEditorgridComponent;
	}

	private void OnKeyEvent(UEEvent _ev)
	{
		if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down &&
			_ev.keyEvent.key == UEKey.f1)
			_editorVisible = !_editorVisible;

		if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Repeat ||
			_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down)
		{
			enum speed = 0.5f;

			if(_ev.keyEvent.isModShift)
			{
				if(_ev.keyEvent.key == UEKey.up)
					_editorCam.sceneNode.position = _editorCam.sceneNode.position + vec3(0,speed,0);
				else if(_ev.keyEvent.key == UEKey.down)
					_editorCam.sceneNode.position = _editorCam.sceneNode.position + vec3(0,-speed,0);
			}
			else
			{
				if(_ev.keyEvent.key == UEKey.up)
					_editorCam.sceneNode.position = _editorCam.sceneNode.position + vec3(0,0,speed);
				else if(_ev.keyEvent.key == UEKey.down)
					_editorCam.sceneNode.position = _editorCam.sceneNode.position + vec3(0,0,-speed);
			}

			if(_ev.keyEvent.key == UEKey.left)
				_editorCam.sceneNode.position = _editorCam.sceneNode.position + vec3(-speed,0,0);
			else if(_ev.keyEvent.key == UEKey.right)
				_editorCam.sceneNode.position = _editorCam.sceneNode.position + vec3(speed,0,0);
				
			enum rotSpeed = 0.01f;
			if(_ev.keyEvent.key == UEKey.w ||
				_ev.keyEvent.key == UEKey.s)
			{
				bool inc = _ev.keyEvent.key == UEKey.w;
				_editorCam.dir = quat.xrotation(rotSpeed * (inc?1:-1)) * _editorCam.dir;
				_editorCam.dir.normalize();
			}
			if(_ev.keyEvent.key == UEKey.a ||
				_ev.keyEvent.key == UEKey.d)
			{
				bool inc = _ev.keyEvent.key == UEKey.a;
				_editorCam.dir = quat.yrotation(rotSpeed * (inc?1:-1)) * _editorCam.dir;
				_editorCam.dir.normalize();
			}
			if(_ev.keyEvent.key == UEKey.q ||
				_ev.keyEvent.key == UEKey.e)
			{
				bool inc = _ev.keyEvent.key == UEKey.q;
				_editorCam.dir = quat.zrotation(rotSpeed * (inc?1:-1)) * _editorCam.dir;
				_editorCam.dir.normalize();
			}

			import std.stdio;
			writefln("cam: %s - %s",_editorCam.sceneNode.position, _editorCam.dir);
		}
	}

	static void renderEditor()
	{
		if(_editorVisible)
		{
			_editorCam.render();
			//TODO: support wireframe shader
			//glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
			//_editorCam.clearBitColor = false;
			//_editorCam.clearBitDepth = false;
			//_editorCam.render();
			//glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
			//_editorCam.clearBitColor = true;
			//_editorCam.clearBitDepth = true;
		}

		renderGrid();

		renderEntities();

		renderEditorGUI();
	}

	static void renderGrid()
	{

	}

	static void renderEntities()
	{

	}

	static void renderEditorGUI()
	{
		int cursorX, cursorY;
		ubyte mouseButtons;
		int mouseScroll;

		imguiBeginFrame(cursorX, cursorY, mouseButtons, mouseScroll);

		if(_editorVisible)
		{
			renderScene();
			imguiDrawText(0, 2, TextAlign.left, "EditorMode (hide with F1)", RGBA(255, 255, 255));
		}
		else
			imguiDrawText(0, 2, TextAlign.left, "EditorMode (show with F1)", RGBA(255, 255, 255));

		imguiEndFrame();
		imguiRender(ue.application.mainWindow.size.width,ue.application.mainWindow.size.height);
	}

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

	private static void renderSceneNode(UESceneNode _node)
	{
		if(_node.entity.hideInEditor)
			return;

		imguiLabel(_node.entity.name);

		imguiIndent();
		foreach(n; _node.children)
		{
			renderSceneNode(n);
		}
		imguiUnindent();
	}
}