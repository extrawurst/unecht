module unecht.core.component;

import unecht.core.events;
import unecht.core.entity;
import unecht;

///
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

package:
	void setEntity(Entity _entity) { m_entity = _entity; }

private:
	Entity m_entity;
}