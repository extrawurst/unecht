module unecht.core.components.editor.mouseControls;

import unecht.core.events;
import unecht.core.entity;
import unecht.core.component;
import unecht.core.components.internal.gui;

import gl3n.linalg;

///
final class UEEditorMouseControls : UEComponent
{
    mixin(UERegisterObject!());
    
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
