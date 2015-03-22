module unecht.core.component;

import unecht.core.events;
import unecht.core.entity;
import unecht.core.scenegraph;
import unecht;

/// binding component between an GameEntity and a SceneNode
class UEComponent
{
	//void OnEnable() {}
	void onUpdate() {}
	//void OnDisable() {}
	
	void onCreate() {}
	
	///
	@property bool enabled() const { return _enabled; }
	///
	@property void enabled(bool _value) { _enabled = _value; }
	///
	@property UEEntity entity() { return _entity; }
	///
	@property UESceneNode sceneNode() { return _entity.sceneNode; }
	
	/// helper
	void registerEvent(UEEventType _type, UEEventCallback _callback)
	{
		ue.events.register(UEEventReceiver(this,_type,_callback));
	}

package:
	void setEntity(UEEntity _entity) { this._entity = _entity; }

private:
	UEEntity _entity;
	//TODO: disabled by default
	bool _enabled = true;
}