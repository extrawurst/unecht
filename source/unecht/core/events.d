module unecht.core.events;

import unecht;

///
enum UEEventType
{
	key,
	text,
	windowSize,
	framebufferSize,
	windowFocus,
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
		bool shift;

		//TODO: impl
		/// is shift mod set
		@property bool isModShift() { return shift; }
	}
	KeyEvent keyEvent;

	struct TextEvent
	{
		dchar character;
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
			if(r.component == _comp)
			{
				r.removed = true;
				dirty = true;
			}
		}
	}

	UEEventReceiver[] receiver;
	bool dirty=false;

	///
	void trigger(UEEvent _ev)
	{
		foreach(r; receiver)
		{
			if(r.removed || !r.component.enabled)
				continue;

			if(r.eventType == _ev.eventType)
			{
				r.eventFunc(_ev);
			}
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