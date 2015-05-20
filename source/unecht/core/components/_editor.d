module unecht.core.components._editor;

version(UEIncludeEditor):

import unecht;

import unecht.core.hideFlags;
import unecht.core.component;
import unecht.core.components.camera;
import unecht.core.components.sceneNode;
import unecht.core.components.material;
import unecht.core.components.misc;
import unecht.core.components.renderer;
import unecht.core.components.internal.gui;

import unecht.core.components.editor.editorGui;
import unecht.core.components.editor.editorMenus;
import unecht.core.components.editor.grid;
import unecht.core.components.editor.mouseControls;

import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;

import derelict.opengl3.gl3;

///
final class UEEditorNodeKeyControls : UEComponent
{
    mixin(UERegisterObject!());

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
            if(_ev.keyEvent.mods.isModShift)
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

	mixin(UERegisterObject!());

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

            if(EditorRootComponent._currentEntity && 
                (_ev.keyEvent.key == UEKey.backspace && _ev.keyEvent.mods.isModSuper) ||
                _ev.keyEvent.key == UEKey.del)
            {
                UEEntity.destroy(EditorRootComponent._currentEntity);
                EditorRootComponent.selectEntity(null);
            }
		}

        keyControls.OnKeyEvent(_ev);
	}
}

///
final class EditorRootComponent : UEComponent {

	mixin(UERegisterObject!());

	private UEEntity editorComponent;

	private static UEEntity gismo;
    private static UEMaterial editorMaterial;

	private static bool _editorVisible;
	private static UECamera _editorCam;
	private static UEEntity _currentEntity;
    private static UEEditorGUI _editorGUI;

    ///
    static @property UEEntity currentEntity() { return _currentEntity; }
    ///
    static @property bool visible() { return _editorVisible; }

    ///
	override void onCreate() {
		super.onCreate;

        sceneNode.hideFlags.set(HideFlags.hideInHirarchie);
        sceneNode.hideFlags.set(HideFlags.dontSaveInScene);
		
		registerEvent(UEEventType.key, &OnKeyEvent);
        registerEvent(UEEventType.updateEditMode, &onEditorUpdate);

        _editorGUI = entity.addComponent!UEEditorGUI;

        entity.addComponent!UEEditorMenus;
        entity.addComponent!UEEditorMouseControls;

		_editorCam = entity.addComponent!UECamera;
		_editorCam.clearColor = vec4(0.1,0.1,0.1,1.0);
		_editorCam.sceneNode.position = vec3(0,5,-20);

		editorComponent = UEEntity.create("subeditor");
		editorComponent.sceneNode.parent = this.sceneNode;
		editorComponent.addComponent!UEEditorComponent;
		editorComponent.sceneNode.enabled = false;

        import unecht.core.components.editor.gismo;
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

        toggleEditor();
	}

    ///
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
    private void onEditorUpdate(UEEvent ev)
    {
        onUpdate();
    }
    
    ///
    private void OnKeyEvent(UEEvent _ev)
	{
		if(_ev.keyEvent.action == UEEvent.KeyEvent.Action.Down &&
			_ev.keyEvent.key == UEKey.f1)
		{
            toggleEditor();
		}
	}

	///
	package static void lookAtNode(UESceneNode node)
	{
		auto camNode = _editorCam.sceneNode;

		import std.stdio;
		writefln("look at: %s %s",node.entity.name,node.position);
		camNode.position = node.position + (camNode.forward*-10.0f);
	}

	///
    private void toggleEditor()
    {
        _editorVisible = !_editorVisible;
        editorComponent.sceneNode.enabled = _editorVisible;
    }

	///
	static void renderEditor()
	{
		if(_editorVisible)
		{
            // render regular but from editor camera pov
			_editorCam.render();

            {
                // render wireframes
                UERenderer.editorMaterial = editorMaterial;
                scope(exit)UERenderer.editorMaterial = null;
                _editorCam.clearBitColor=false;
                scope(exit)_editorCam.clearBitColor=true;

                _editorCam.render();
            }

            // render gismo
            _editorCam.visibleLayers = 1<<UELayer.editor;
            _editorCam.clearBitColor=false;
            _editorCam.render();
            _editorCam.clearBitColor=true;
            _editorCam.visibleLayers = UECameraDefaultLayers;
		}

        _editorGUI.render();
	}

    ///
    public static void selectEntity(UEEntity _entity)
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