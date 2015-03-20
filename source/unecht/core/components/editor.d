module unecht.core.components.editor;

import unecht;

import unecht.core.component;

import imgui;

///
final class EditorComponent : UEComponent {

	private static bool _editorVisible;
	
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
	}

	private void OnKeyEvent(UEEvent _ev)
	{
		if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down &&
			_ev.keyEvent.key == UEKey.f1 &&
			_ev.keyEvent.isModShift)
			_editorVisible = !_editorVisible;
	}

	static void renderEditor()
	{
		renderEditorGUI();

		renderGrid();

		renderEntities();
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