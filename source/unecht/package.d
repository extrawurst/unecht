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
	void onUpdate() {}
	//void OnDisable() {}

	void onCreate() {}

	///
	@property Entity entity() {return m_entity;}
	///
	//@property Transform transform() {return m_entity;}

	/// helper
	void registerEvent(EventType _type, EventCallback _callback)
	{
		ue.events.register(EventReceiver(this,_type,_callback));
	}

private:
	Entity m_entity;

	private void setEntity(Entity _entity) { m_entity = _entity; }
}

///
class Renderer : Component {
	
	override void onCreate() {
		super.onCreate;
		

	}

	override void onUpdate() {

		
	}
}

class Entity
{
	void addComponent(T)()
	{
		auto newt = new T();
		newt.setEntity(this);

		components ~= newt;
	}

	void addComponent(string _type)
	{
		auto newcomp = cast(Component)Object.factory(_type);
		assert(newcomp);

		newcomp.setEntity(this);

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
