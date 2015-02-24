module unecht.core.component;

import unecht.core.events;
import unecht.core.entity;
import unecht;

///
class UEComponent
{
	//void OnEnable() {}
	void onUpdate() {}
	//void OnDisable() {}
	
	void onCreate() {}
	
	///
	@property UEEntity entity() {return m_entity;}
	///
	//@property Transform transform() {return m_entity;}
	
	/// helper
	void registerEvent(UEEventType _type, UEEventCallback _callback)
	{
		ue.events.register(UEEventReceiver(this,_type,_callback));
	}

package:
	void setEntity(UEEntity _entity) { m_entity = _entity; }

private:
	UEEntity m_entity;
}