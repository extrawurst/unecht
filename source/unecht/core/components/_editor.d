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

import unecht.core.components.editor.editorGui;
import unecht.core.components.editor.grid;

import unecht.gl.vertexBufferObject;
import unecht.gl.vertexArrayObject;

import derelict.opengl3.gl3;

///
final class UEEditorMouseControls : UEComponent
{
    mixin(UERegisterComponent!());

	static immutable SPEED_NORMAL = 0.02f;
	static immutable SPEED_FAST = 0.25f;

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
                moveMode = !_ev.mouseButtonEvent.mods.isModAlt;
            }
        }
        else if(_ev.eventType == UEEventType.mousePos)
        {
            auto curPos = vec2(_ev.mousePosEvent.x,_ev.mousePosEvent.y);
            auto delta = curPos - lastMousePos;

            if(mouseDown)
            {
                onDrag(delta,0,_ev.mousePosEvent.mods.isModShift);
            }

            lastMousePos = curPos;
        }
        else if(_ev.eventType == UEEventType.mouseScroll)
        {
			if(!UEGui.capturesMouse)
				onDrag(vec2(0), _ev.mouseScrollEvent.yoffset,_ev.mouseScrollEvent.mods.isModShift);
        }
    }

    private void onDrag(vec2 delta, double scroll=0, bool fastMode=false)
    {
		auto speedNow = fastMode?SPEED_FAST:SPEED_NORMAL;

        //TODO: only zoom like this in move mode and move cam in direction of the ray (eye, cursorPosDir-from-screen-to-frustum)
        sceneNode.position = sceneNode.position + (sceneNode.forward * scroll * speedNow * 10.0f);

        if(moveMode)
        {
            sceneNode.position = sceneNode.position + (sceneNode.right * delta.x * -speedNow);
            sceneNode.position = sceneNode.position + (sceneNode.up * delta.y * speedNow);
        }
        else
        {
            sceneNode.angles = sceneNode.angles + vec3(delta.y*speedNow*3,delta.x*-speedNow*3,0);
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

	mixin(UERegisterComponent!());

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
            toggleEditor();
		}
	}

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
    package static void selectEntity(UEEntity _entity)
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