module unecht.core.component;

import derelict.util.system;

public import unecht.core.serialization.serializer;
public import unecht.core.serialization.mixins;
import unecht.core.events:UEEventType;
import unecht.core.entity;
import unecht.core.components.sceneNode;
import unecht.core.object;
import unecht;

///
template UEObjectCreateMenuItem()
{
    enum UEObjectCreateMenuItem = q{
        static if(!is(typeof(this) == UEComponent) && is(typeof(this) : UEComponent))
        {
            version(UEIncludeEditor)import unecht.core.components.editor.menus;
            version(UEIncludeEditor)import unecht.meta.uda;
            
            version(UEIncludeEditor)override void getMenuItems(ref EditorMenuItem[] items)
            {
                super.getMenuItems(items);
                
                alias T = typeof(this);
                
                foreach(m; __traits(derivedMembers, T))
                {
                    static if(__traits(isStaticFunction, __traits(getMember, T, m)))
                    {
                        static if(hasUDA!(__traits(getMember, T, m), MenuItem))
                        {
                            alias MemberType = typeof(&__traits(getMember, T, m));
                            
                            static if(is(MemberType : MenuItemFunc))
                            {
                                alias uda = getUDA!(__traits(getMember, T, m), MenuItem);
                                
                                items ~= EditorMenuItem(uda.name, &__traits(getMember, T, m), uda.validate);
                            }
                            else
                            {
                                static assert(false, format("%s.%s is annotated as MenuItem but has type: '%s' expected '%s'",
                                        T.stringof,m,MemberType.stringof,MenuItemFunc.stringof));
                            }
                        }
                    }
                }
            }
        }
    };
}

///
template UEObjectSerialization()
{
    enum UEObjectSerialization = q{

        private{
            mixin generateObjectSerializeFunc!(serializeMember, UESerializer, "serialize");
            mixin generateObjectSerializeFunc!(deserializeMember, UEDeserializer, "deserialize");

            void serializeMember(T,M)(string m,ref M member, ref UESerializer serializer, UECustomFuncSerialize!M customFunc=null)
            {
                serializer.serializeObjectMember!(T,M)(this, m, member, customFunc);
            }

            void deserializeMember(T,M)(string m, ref M member, ref UEDeserializer serializer, UECustomFuncDeserialize!M customFunc=null)
            {
                serializer.deserializeObjectMember!(T,M)(this, this.instanceId.toString(), m, member, customFunc);
            }
        }

        override void serialize(ref UESerializer serializer) 
        {
            import unecht.core.hideFlags;
            if(hideFlags.isSet(HideFlags.dontSaveInScene))
                return;

            alias T = typeof(this);

            iterateAllSerializables!(T)(this, serializer);

            super.serialize(serializer);
        }

        override void deserialize(ref UEDeserializer serializer, string uid=null) 
        {
            super.deserialize(serializer,uid);
            
            alias T = typeof(this);

            iterateAllSerializables!(T)(this, serializer);
        }
    };
}

///
template UEObjectCreateEditor()
{
    enum UEObjectCreateEditor = q{

        version(UEIncludeEditor)import unecht.core.componentManager:IComponentEditor;

        version(UEIncludeEditor)
        override IComponentEditor createEditor()
        {
            import unecht.core.defaultInspector;
            
            alias T = typeof(this);

            static UEDefaultInspector!T editor;

            if(editor is null)
                editor = new UEDefaultInspector!T();

            return editor;
        }
    };
}

///
template UERegisterObject()
{
    enum UERegisterObject = 
        UEObjectSerialization!() 
        ~ UEObjectCreateMenuItem!() 
        ~ UEObjectCreateEditor!() 
        ~ q{version(UEIncludeEditor)override @property string typename() { return typeof(this).stringof; }};
}

/// binding component between an GameEntity and a SceneNode
abstract class UEComponent : UEObject
{
    mixin(UERegisterObject!());

	//void OnEnable() {}
	void onUpdate() {}
	//void OnDisable() {}
	
    ///
	void onCreate() {}
    ///
    void onDestroy() {}
    ///
    void onCollision(UEComponent _collider) {}
	
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

    ///
    version(UEIncludeEditor)void getMenuItems(ref EditorMenuItem[] items){}

package:
	final void setEntity(UEEntity _entity) { this._entity = _entity; }

private:
    @Serialize
	UEEntity _entity;

	//TODO: disabled by default
    @Serialize
	bool _enabled = true;
}