module unecht.core.events;

import unecht;

///
enum EventType
{
	Key,
}

///
struct Event
{
	EventType eventType;
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
		//bool shift;
	}
	KeyEvent keyEvent;
}

///
alias EventCallback = void delegate (Event);

///
struct EventReceiver
{
	Component component;
	EventType eventType;
	EventCallback eventFunc;

	private bool removed=false;
}

///
interface Events
{
	///
	void register(EventReceiver);
	///
	void unRegister(EventReceiver);
	///
	void removeComponent(Component);
}

///
class EventsSystem : Events
{
	///
	override void register(EventReceiver _receiver)
	{
		receiver ~= _receiver;
	}

	///
	override void unRegister(EventReceiver _receiver)
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
	override void removeComponent(Component _comp)
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

	EventReceiver[] receiver;
	bool dirty=false;

	///
	void trigger(Event _ev)
	{
		foreach(r; receiver)
		{
			if(r.removed)
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