module unecht.core.component;

import derelict.util.system;
public import sdlang;

public import unecht.core.componentSerialization;
import unecht.core.events:UEEventType;
import unecht.core.entity;
import unecht.core.components.sceneNode;
import unecht.core.object;
import unecht;

///
template UERegisterObject()
{
    enum UERegisterObject = q{
        version(UEIncludeEditor)override @property string typename() { return typeof(this).stringof; }

        static if(!is(typeof(this) == UEComponent) && is(typeof(this) : UEComponent))
        {
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

        override void serialize(ref UESerializer serializer) 
        {
            import unecht.meta.uda;

            alias T = typeof(this);
            alias v = this;
            
            //pragma (msg, "----------------------------------------");
            //pragma (msg, T.stringof);
            //pragma (msg, __traits(derivedMembers, T));

            foreach(m; __traits(derivedMembers, T))
            {
                enum isMemberVariable = is(typeof(() {
                            __traits(getMember, v, m) = __traits(getMember, v, m).init;
                        }));
                
                enum isMethod = is(typeof(() {
                            __traits(getMember, v, m)();
                        }));
                
                enum isNonStatic = !is(typeof(mixin("&T."~m)));
                
                //pragma(msg, .format("- %s (%s,%s,%s)",m,isMemberVariable,isNonStatic,isMethod));
                
                static if(isMemberVariable && isNonStatic && !isMethod) {
                    
                    enum hasSerializeUDA = hasUDA!(mixin("T."~m), Serialize);
                    
                    //pragma(msg, .format("> '%s' (%s)", m, hasSerializeUDA));
                    
                    static if(hasSerializeUDA)
                    {
                        alias M = typeof(__traits(getMember, v, m));
                        
                        //enum memberOffset = __traits(getMember, v, m).offsetof;
                        
                        serializer.serializeObjectMember!(T,M)(this, m, __traits(getMember, v, m));
                    }
                }
            }

            super.serialize(serializer);
        }
        
        override void deserialize(ref UEDeserializer serializer, string uid=null) 
        {
            super.deserialize(serializer,uid);

            uid = this.instanceId.toString();

            import unecht.meta.uda;
            
            alias T = typeof(this);
            alias v = this;
            
            foreach(m; __traits(derivedMembers, T))
            {
                enum isMemberVariable = is(typeof(() {
                            __traits(getMember, v, m) = __traits(getMember, v, m).init;
                        }));
                
                enum isMethod = is(typeof(() {
                            __traits(getMember, v, m)();
                        }));
                
                enum isNonStatic = !is(typeof(mixin("&T."~m)));
                
                static if(isMemberVariable && isNonStatic && !isMethod) {
                    
                    enum hasSerializeUDA = hasUDA!(mixin("T."~m), Serialize);
                    
                    static if(hasSerializeUDA)
                    {
                        alias M = typeof(__traits(getMember, v, m));
                        
                        serializer.deserializeObjectMember!(T,M)(this, uid, m, __traits(getMember, v, m));
                    }
                }
            }
        }
    };
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