module unecht.glfw.joysticks;

import unecht.core.events;

import derelict.glfw3.glfw3;

static immutable MAX_AXES = 8;
static immutable MAX_BUTTONS = 12;

///
struct UEJoystickInfo
{
    uint axesCount;
    uint buttonCount;
    string name;
}

///
struct UEJoystickState
{
    UEJoystickInfo info;

    bool connected=false;
    float* glfwAxesPtr;
    ubyte* glfwButtonPtr;
    float[MAX_AXES] axesState;
    ubyte[MAX_BUTTONS] buttonState;
}

///
struct GLFWJoysticks
{
    private UEJoystickState[4] _states;
    private UEEventsSystem _events;

    void init(UEEventsSystem events)
    {
        _events = events;
    }

    void update()
    {
        foreach(int id, ref state; _states)
        {
            auto presentNow = glfwJoystickPresent (id);

            if(presentNow && !state.connected)
            {
                state.connected = true;
                connect(id,state);
                continue;
            }
            else if(!presentNow && state.connected)
            {
                disconnect(id,state.info.name);
                state.info.name.length=0;
                state.connected = false;
                state.glfwAxesPtr = null;
                state.glfwButtonPtr = null;
                state.axesState[] = 0.0f;
                state.buttonState[] = 0;
                continue;
            }

            if(presentNow)
            {
                auto axesState = state.glfwAxesPtr[0..state.info.axesCount];

                auto buttonState = state.glfwButtonPtr[0..state.info.buttonCount];

                if(buttonState != state.buttonState[0..state.info.buttonCount])
                {
                    triggerButtonEvent(buttonState,state);
                    state.buttonState[0..state.info.buttonCount] = buttonState;
                }

                if(axesState != state.axesState[0..state.info.axesCount])
                {
                    state.axesState[0..state.info.axesCount] = axesState;
                    triggerAxesEvent(axesState,state);
                }
            }
        }
    }

    void triggerAxesEvent(float[] newState, in UEJoystickState state)
    {
        UEEvent ev;
        ev.eventType = UEEventType.joystickAxes;
        ev.joystickAxes.axes = newState;

        _events.trigger(ev);
    }

    void triggerButtonEvent(in ubyte[] newState, in UEJoystickState state)
    {
        foreach(uint i,button; newState)
        {
            if(newState[i] != state.buttonState[i])
            {
                UEEvent ev;
                ev.eventType = UEEventType.joystickButton;
                ev.joystickButton.buttonId = i;
                ev.joystickButton.pressed = button==GLFW_PRESS;
                
                _events.trigger(ev);
            }
        }
    }

    void connect(int id, ref UEJoystickState state)
    {
        state.info.name.length=0;
        auto cName = glfwGetJoystickName (id);
        if(cName)
        {
            import std.conv;
            state.info.name = to!string(cName);
        }

        int axesCount;
        state.glfwAxesPtr = glfwGetJoystickAxes (id, &axesCount);

        int buttonCount;
        state.glfwButtonPtr = glfwGetJoystickButtons (id, &buttonCount);

        import std.algorithm:min;
        state.info.axesCount = min(axesCount,MAX_AXES);
        state.info.buttonCount = min(buttonCount,MAX_BUTTONS);

        //trigger event
        {
            UEEvent ev;
            ev.eventType = UEEventType.joystickStatus;
            ev.joystickStatus.connected = true;

            ev.joystickStatus.name = state.info.name;
            ev.joystickStatus.id = id;
            ev.joystickStatus.buttonCount = state.info.buttonCount;
            ev.joystickStatus.axesCount = state.info.axesCount;

            _events.trigger(ev);
        }
    }

    void disconnect(int id, string name)
    {
        UEEvent ev;
        ev.eventType = UEEventType.joystickStatus;
        ev.joystickStatus.connected = false;
        
        ev.joystickStatus.name = name;
        ev.joystickStatus.id = id;

        _events.trigger(ev);
    }
}