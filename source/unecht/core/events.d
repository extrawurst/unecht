module unecht.core.events;

import unecht.core.component;
import unecht.core.types:UESize;
public import unecht.glfw.types:UEKey;

///
enum UEEventType
{
    updateEditMode,
	key,
	text,
	windowSize,
	framebufferSize,
	windowFocus,
    mouseScroll,
    mouseButton,
    mousePos,
    joystickStatus,
    joystickAxes,
    joystickButton
}

///
struct EventModKeys
{
	private bool shiftDown;
	private bool ctrlDown;
	private bool altDown;
	private bool superDown;

    void set(bool modShift,bool modCtrl,bool modAlt,bool modSuper) nothrow
    {
        shiftDown = modShift;
        ctrlDown = modCtrl;
        superDown = modSuper;
        altDown = modAlt;
    }

    ///
    void setFromBitMaskGLFW(int mask) nothrow
    {
        import unecht.core.stdex:testBitMask;
        import derelict.glfw3.glfw3;

        shiftDown = testBitMask(mask,GLFW_MOD_SHIFT);
        ctrlDown = testBitMask(mask,GLFW_MOD_CONTROL);
        altDown = testBitMask(mask,GLFW_MOD_ALT);
        superDown = testBitMask(mask,GLFW_MOD_SUPER);
    }

	/// is shift mod set
	@property bool isModShift() const { return shiftDown; }
	///
	@property bool isModCtrl() const { return ctrlDown; }
	///
	@property bool isModAlt() const { return altDown; }
	///
	@property bool isModSuper() const { return superDown; }
}

///
struct UEEvent
{
	UEEventType eventType;
	struct KeyEvent
	{
		enum Action
		{
			Down,
			Up,
			Repeat,
		}

		UEKey key;
		Action action;
		EventModKeys mods;
	}
	KeyEvent keyEvent;

	struct TextEvent
	{
		dchar character;
        EventModKeys mods;
	}
	TextEvent textEvent;

	struct SizeEvent
	{
		UESize size;
	}
	SizeEvent windowSizeEvent;
	SizeEvent framebufferSizeEvent;

	struct FocusEvent
	{
		bool gainedFocus;
	}
	FocusEvent focusEvent;

    struct MouseScrollEvent
    {
        double xoffset;
        double yoffset;
        EventModKeys mods;
    }
    MouseScrollEvent mouseScrollEvent;

    struct MouseButtonEvent
    {
        enum Action 
        {
            down,
            up,
            click
        }

        int button;
        Action action;
        MousePosEvent pos;

        ///
        @property bool isDown() const {return action==Action.down;}
        ///
        @property bool isClick() const {return action==Action.click;}
    }
    MouseButtonEvent mouseButtonEvent;

    struct MousePosEvent
    {
        double x;
        double y;

		EventModKeys mods;
    }
    MousePosEvent mousePosEvent;

    struct JoystickStatus
    {
        uint id;
        string name;
        uint buttonCount;
        uint axesCount;
        bool connected;
    }
    JoystickStatus joystickStatus;

    struct JoystickButton
    {
        uint buttonId;
        bool pressed;
    }
    JoystickButton joystickButton;

    struct JoystickAxes
    {
        uint id;
        float[] axes;
    }
    JoystickAxes joystickAxes;
}

///
alias UEEventCallback = void delegate (UEEvent);

///
struct UEEventReceiver
{
	UEComponent component;
	UEEventType eventType;
	UEEventCallback eventFunc;

	private bool removed=false;
}

///
interface UEEvents
{
	///
	void register(UEEventReceiver);
	///
	void unRegister(UEEventReceiver);
	///
	void removeComponent(UEComponent);
    ///
	//TODO: makes this one only schedule and trigger all events in the main loop (#145)
    void trigger(UEEvent) nothrow;
}

///
final class UEEventsSystem : UEEvents
{
	///
	override void register(UEEventReceiver _receiver)
	{
		receiver ~= _receiver;
	}

	///
	override void unRegister(UEEventReceiver _receiver)
	{
		foreach(ref r; receiver)
		{
			if(r.component == _receiver.component && r.eventType == _receiver.eventType)
			{
				r.removed = true;
				dirty = true;
			}
		}
	}

	///
	override void removeComponent(UEComponent _comp)
	{
		foreach(ref r; receiver)
		{
			if(r.component is _comp)
			{
				r.removed = true;
				dirty = true;
                r.component = null;
			}
		}
	}

	UEEventReceiver[] receiver;
	bool dirty=false;

	///
	override void trigger(UEEvent _ev) nothrow
	{
		try{
			foreach(r; receiver)
			{
				//TODO: support correct recursive enabled/disabled values 
				if(r.removed || (!r.component.enabled) || (!r.component.sceneNode.enabled))
					continue;

				if(r.eventType == _ev.eventType)
				{
					r.eventFunc(_ev);
				}
			}
		}
		catch(Throwable e){
			import unecht.core.logger:log;
			try log.errorf("%s",e);
			catch(Throwable){}
		}
	}

	/// remove deleted entries
	void cleanUp()
	{
		if(dirty)
		{
			//TODO:
		}

		dirty = false;
	}
}