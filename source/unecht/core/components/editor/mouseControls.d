module unecht.core.components.editor.mouseControls;

version(UEIncludeEditor):

import unecht;
import unecht.core.events;
import unecht.core.entity;
import unecht.core.component;
import unecht.core.components.internal.gui;
import unecht.core.components.editor.mousePicking;
import unecht.core.components.editor.gismo;

import gl3n.linalg;

///
final class UEEditorMouseControls : UEComponent
{
    mixin(UERegisterObject!());
    
    static immutable SPEED_NORMAL = 0.02f;
    static immutable SPEED_FAST = 0.25f;
    static immutable MOUSE_CLICK_TIMEOUT = 1.0f;
    static immutable MOUSE_CLICK_DISTANCE_THRESHOLT = 2.0f;
    
    private struct MouseClickState
    {
        int mouseButtonDown;
        float time = 0;
        vec2 pos;
    }

    private bool mouseDown;
    private bool moveMode;
    private vec2 lastMousePos;
    private MouseClickState mouseClickState;
    
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
            if(_ev.mouseButtonEvent.isClick)
            {
                onClick(_ev.mouseButtonEvent);
                return;
            }

            if(!UEGui.capturesMouse)
            {
                if(_ev.mouseButtonEvent.button == 0)
                {
                    mouseDown = _ev.mouseButtonEvent.isDown;
                    moveMode = !_ev.mouseButtonEvent.pos.mods.isModAlt;
                }

                if(_ev.mouseButtonEvent.isDown)
                {
                    mouseClickState.mouseButtonDown = _ev.mouseButtonEvent.button;
                    mouseClickState.time = ue.tickTime;
                    mouseClickState.pos = vec2(_ev.mouseButtonEvent.pos.x,_ev.mouseButtonEvent.pos.y);
                }
                else
                {
                    auto mpos = vec2(_ev.mouseButtonEvent.pos.x,_ev.mouseButtonEvent.pos.y);
                    auto delta = mouseClickState.pos - mpos;
                    if(_ev.mouseButtonEvent.button == mouseClickState.mouseButtonDown && 
                        ue.tickTime - mouseClickState.time < MOUSE_CLICK_TIMEOUT &&
                        delta.length < MOUSE_CLICK_DISTANCE_THRESHOLT)
                    {
                        triggerMouseClick(mouseClickState.mouseButtonDown, mpos);
                    }
                }
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

    private static triggerMouseClick(int button, vec2 pos)
    {
        UEEvent ev;
        ev.eventType = UEEventType.mouseButton;
        ev.mouseButtonEvent.action = UEEvent.MouseButtonEvent.Action.click;
        ev.mouseButtonEvent.button = button;
        ev.mouseButtonEvent.pos.x = pos.x;
        ev.mouseButtonEvent.pos.y = pos.y;

        ue.events.trigger(ev);
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

    private void onClick(UEEvent.MouseButtonEvent event)
    {
        auto pos = vec2(event.pos.x,event.pos.y);
        import unecht.core.components._editor;

        auto ray = EditorRootComponent.camera.screenToRay(pos);
     
        MousePicking.onPick(ray);
    }
}
