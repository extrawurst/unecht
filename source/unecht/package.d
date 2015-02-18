module unecht;

public import unecht.core.types;
public import unecht.core.events;
import unecht.glfw.application;

class UnechtException : Exception
{
	this(string _str)
	{
		super(_str);
	}
}

alias DebugTickFunc = void function (double);

class Component
{
	//void OnEnable() {}
	//void OnUpdate() {}
	//void OnDisable() {}

	void onCreate() {}

	/// helper
	void registerEvent(EventType _type, EventCallback _callback)
	{
		ue.events.register(EventReceiver(this,_type,_callback));
	}
}

class Entity
{
	void addComponent(T)()
	{
		components ~= new T();
	}

	void addComponent(string _type)
	{
		auto newcomp = cast(Component)Object.factory(_type);
		assert(newcomp);

		newcomp.onCreate();

		components ~= newcomp;
	}

	static auto create()
	{
		return new Entity();
	}

private:
	Entity parent;
	Entity[] children;
	
	Component[] components;
}

struct Unecht
{
	WindowSettings windowSettings;
	DebugTickFunc[] debugTick;
	Entity currentScene;
	string startComponent;
	Application application;
	Events events;
}

__gshared Unecht ue;
