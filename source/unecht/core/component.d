module unecht.core.component;

import derelict.util.system;
public import sdlang;

public import unecht.core.componentSerialization;
import unecht.core.events:UEEventType;
import unecht.core.entity;
import unecht.core.components.sceneNode;
import unecht;

///
template UERegisterComponent()
{
	enum UERegisterComponent = q{
        version(UEIncludeEditor)override @property string name() { return typeof(this).stringof; }

        override void serialize(ref UESerializer serializer) 
        {
            serializer.serialize(this);
        }
	};
}

/// binding component between an GameEntity and a SceneNode
abstract class UEComponent
{
	///
	version(UEIncludeEditor)abstract @property string name();

	//void OnEnable() {}
	void onUpdate() {}
	//void OnDisable() {}
	
    ///
	void onCreate() {}
    ///
    void onDestroy() {}
    ///
    void onCollision(UEComponent _collider) {}

    ///
    void serialize(ref UESerializer serializer)
    {
        //TODO: serialize entity

        /+Tag memberTag = new Tag(sdlTag);
        memberTag.name = "enabled";
        memberTag.add(Value(_enabled));+/
    }
	
    @nogc final nothrow {
    	///
    	@property bool enabled() const { return _enabled; }
    	///
    	@property void enabled(bool _value) { _enabled = _value; }
    	///
    	@property UEEntity entity() { return _entity; }
    	///
    	@property UESceneNode sceneNode() { return _entity.sceneNode; }
    }
	
	/// helper
	final void registerEvent(UEEventType _type, UEEventCallback _callback)
	{
		ue.events.register(UEEventReceiver(this,_type,_callback));
	}

package:
	final void setEntity(UEEntity _entity) { this._entity = _entity; }

private:
	UEEntity _entity;
	//TODO: disabled by default
    @Serialize
	bool _enabled = true;
}