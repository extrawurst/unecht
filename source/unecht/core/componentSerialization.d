module unecht.core.componentSerialization;

import std.conv;
import std.traits:isPointer,Unqual,BaseClassesTuple;

import unecht.core.component;
import unecht.meta.uda;
import unecht.core.entity;
import unecht.core.object;
import sdlang;

import std.string:format;

enum isSerializerBaseType(T) = 
        is( T : bool         ) ||
        is( T : string       ) ||
        is( T : dchar        ) ||
        is( T : int          ) ||
        is( T : long         ) ||
        is( T : float        ) ||
        is( T : double       ) ||
        is( T : real         ) ||
        is( T : ubyte[]      )
        ;

enum isExactSerializerBaseType(T) = 
    is( T == bool         ) ||
        is( T == string       ) ||
        is( T == dchar        ) ||
        is( T == int          ) ||
        is( T == long         ) ||
        is( T == float        ) ||
        is( T == double       ) ||
        is( T == real         ) ||
        is( T == ubyte[]      )
        ;
        
mixin template generateSerializeFunc(alias Func)
{
    void iterateAllSerializables(T)(ref T v, Tag tag)
    {
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
                
                enum isPublic = __traits(getProtection, __traits(getMember, v, m)) == "public";
                
                enum hasSerializeUDA = hasUDA!(mixin("T."~m), Serialize);
                
                enum hasNonSerializeUDA = hasUDA!(mixin("T."~m), NonSerialize);
                
                //pragma(msg, .format("> %s (%s,%s,%s)",m,isPublic,hasSerializeUDA,hasNonSerializeUDA));
                
                static if((isPublic || hasSerializeUDA) && !hasNonSerializeUDA)
                {
                    //pragma(msg, "-> "~m);

                    Func(__traits(getMember, v, m), tag, m);
                }
            }
        }
    }
}

import std.uuid;

///
struct UESerializer
{
    struct SerializerUID
    {
        ubyte[20] nameHash;
        UUID refId;
    }

    private SerializerUID[] alreadySerialized;

    private Tag dependencies;
    private Tag content;
    private bool rootWritten=false;

    mixin generateSerializeFunc!serializeMemberWithName;

    void serialize(T)(T v)
        if(is(T:UEObject))
    {
        if(!dependencies)
            dependencies = new Tag();
        if(!content)
            content = new Tag();

        dependencies.name = "dependencies";
        content.name = "content";

        if(!rootWritten)
        {
            rootWritten = true;
            serializeTo(v, content);
        }
        else
        {
            serializeTo(v, dependencies);
        }
    }

    private bool isCachedRefElseCache(T)(T v,ref UUID refId)
        if(is(T : UEObject))
    {
        import std.algorithm:countUntil;
        import std.digest.sha;

        SerializerUID uid;
        uid.refId = refId = v.instanceId;
        uid.nameHash = sha1Of(Unqual!(T).stringof);
        
        if(alreadySerialized.countUntil(uid) != -1)
        {
            return true;
        }

        alreadySerialized ~= uid;
        return false;
    }

    private void serializeTo(T)(T v, Tag parent)
    {
        UUID refId;
        if(isCachedRefElseCache(v,refId))
            return;

        Tag componentTag = new Tag(parent);
        componentTag.add(new Attribute("uid", Value(to!string(refId))));
        componentTag.name = Unqual!(T).stringof;
        
        iterateAllSerializables!(T)(v, componentTag);
    }

    private void serializeMemberWithName(T)(T v, Tag tag, string membername)
    {
        Tag memberTag = new Tag(tag);
        memberTag.name = membername;

        serializeMember(v, memberTag);
    }
    
    void serializeMember(T)(T val, Tag parent)
        if(is(T : UEObject))
    {
        if(val !is null)
        {
            val.serialize(this);

            auto classId = val.instanceId;
            parent.add(Value(to!string(classId)));
            parent.add(new Attribute("type", Value(typeid(val).toString())));
        }
    }

    static void serializeMember(T)(in ref T val, Tag parent)
        if(is(T == enum))
    {
        parent.add(Value(cast(int)val));
    }

    private void serializeMember(T)(T val, Tag parent)
        if(__traits(isStaticArray, T))
    {
        foreach(v; val)
        {
            auto t = new Tag(parent);
            serializeMember(v,t);
        }
    }

    private void serializeMember(T)(T[] val, Tag parent)
        if( (isSerializerBaseType!T && !is(T : char)) ||
            (is(T:UEComponent) || is(T:UEEntity)))
    {
        foreach(v; val)
        {
            auto t = new Tag(parent);
            serializeMember(v,t);
        }
    }

    private void serializeMember(T)(T v, Tag parent)
        if(is(T == struct))
    {
        iterateAllSerializables!(T)(v, parent);
    }

    static void serializeMember(T)(T val, Tag parent)
        if( isSerializerBaseType!T && !is(T == enum) && !__traits(isStaticArray,T))
    {
        static if(isExactSerializerBaseType!T)
            parent.add(Value(val));
        else
            parent.add(Value(to!string(val)));
    }

    string toString()
    {
        auto root = new Tag;

        root.add(content);
        root.add(dependencies);

        return root.toSDLDocument();
    }
}

struct UEDeserializer
{
    import unecht.core.components.sceneNode;

    struct LoadedObject
    {
        UEObject o;
        string uid;
    }

    private Tag content;
    private Tag dependencies;
    private bool rootRead;
    private LoadedObject[] objectsLoaded;
    private UESceneNode dummy;

    mixin generateSerializeFunc!deserializeFromMemberName;

    this(string input)
    {
        dummy = new UESceneNode;
        import std.stdio;
        auto root =  parseSource(input);

        content = root.all.tags["content"][0];
        //writefln("%s",root.all.tags[0]);
        assert(content !is null);
        dependencies = root.all.tags["dependencies"][0];
        assert(dependencies !is null);
    }
    
    string deserialize(T)(T v, string uid)
        if(is(T:UEObject))
    {
        if(!uid || uid.length == 0)
        {
            auto contentRoot = content.all.tags.front;

            assert(T.stringof == contentRoot.name, format("content name: '%s' (expected '%s')",contentRoot.name, T.stringof));

            string res = contentRoot.attributes["uid"][0].value.get!string;

            storeLoadedRef(v,res);

            deserializeFromTag(v, contentRoot);

            return res;
        }
        else
        {
            return deserializeId(v,uid);
        }
    }

    private string deserializeId(T)(T v, string uid)
        if(is(T:UEObject))
    {
        auto tag = findObject(T.stringof, uid);
        assert(tag, format("obj not found: '%s' (%s)",T.stringof, uid));

        deserializeFromTag(v,tag);

        return uid;
    }

    private Tag findObject(string objectType, string objectId)
    {
        auto objects = dependencies.all.tags[objectType];
        foreach(Tag o; objects)
        {
            auto uid = o.attributes["uid"];

            if(!uid.empty && uid[0].value == objectId)
            {
                return o;
            }
        }

        return null;
    }

    private void deserializeFromTag(T)(T v, Tag node)
        if(is(T:UEObject))
    {
        iterateAllSerializables!T(v, node);
    }

    private void deserializeFromMemberName(T)(ref T v, Tag tag, string membername)
    {
        auto memberTag = tag.all.tags[membername][0];
        assert(memberTag);
        
        deserializeMember(v, memberTag);
    }

    private void deserializeFromMemberName(T)(T v, Tag tag, string membername)
    {
        auto memberTag = tag.all.tags[membername][0];
        assert(memberTag);
        
        deserializeMember(v, memberTag);
    }
    
    void deserializeMember(T)(ref T val, Tag parent)
        if(is(T : UEObject))
    {
        if(parent.values.length == 0)
            return;

        assert(parent.values.length == 1, format("[%s] wrong value count %s",T.stringof,parent.values.length));

        const uid = parent.values[0].get!string;
        assert(uid.length > 0);

        auto r = findLoadedRef(uid);
        if(r)
        {
            val = cast(T)r;
            assert(val);
        }
        else
        {
            static if(is(T:UEComponent))
            {
                auto typename = parent.attributes["type"][0].value.get!string;
                val = cast(T)Object.factory(typename);
                assert(val, format("could not create: %s",typename));
            }
            else
                val = UEEntity.create(null,dummy);

            storeLoadedRef(val,uid);

            val.deserialize(this, uid);

            static if(is(T:UEComponent))
                val.onCreate();
        }
    }

    private UEObject findLoadedRef(string uid)
    {
        alias objArray = objectsLoaded;

        foreach(o; objArray)
        {
            if(o.uid == uid)
                return o.o;
        }

        return null;
    }

    private void storeLoadedRef(UEObject v, string uid)
    {
        objectsLoaded ~= LoadedObject(v,uid);
    }
    
    private static void deserializeMember(T)(ref T val, Tag parent)
        if(is(T == enum))
    {
        val = cast(T)parent.values[0].get!int;
    }

    private void deserializeMember(T)(ref T val, Tag parent)
        if(__traits(isStaticArray,T))
    {
        assert(parent.all.tags.length == T.length);
        size_t idx=0;
        foreach(tag; parent.all.tags)
        {
            deserializeMember(val[idx++],tag);
        }
    }

    private void deserializeMember(T)(ref T[] val, Tag parent)
        if((isSerializerBaseType!T && !is(T : char)) ||
            (is(T:UEComponent) || is(T:UEEntity) ))
    {
        val.length = parent.all.tags.length;
        size_t idx=0;
        foreach(tag; parent.all.tags)
        {
            deserializeMember(val[idx++],tag);
        }
    }

    private void deserializeMember(T)(ref T v, Tag parent)
        if(is(T == struct))
    {
        iterateAllSerializables(v, parent);
    }

    private static void deserializeMember(T)(ref T val, Tag parent)
        if( isSerializerBaseType!T && !is(T == enum) && !__traits(isStaticArray,T))
    {
        if(parent.values.length > 0)
        {
            assert(parent.values.length == 1, format("deserializeMember!(%s)('%s'): %s",T.stringof, parent.name, parent.values.length));

            static if(isExactSerializerBaseType!T)
                val = parent.values[0].get!T;
            else
                val = to!T(parent.values[0].get!string);
        }
    }
}

/// UDA to mark serialization fields
struct Serialize{}
/// UDA to mark serialization fields to not be serialized
struct NonSerialize{}
/// UDA to mark a type that contains custom serialization methods
struct CustomSerializer{}

version(unittest):

class Comp1: UEComponent
{
    mixin(UERegisterComponent!());
    
    int val;
}

unittest
{
    import std.stdio;
    import unecht.core.components.sceneNode;
    import unecht;

    class BaseComp: UEComponent
    {
        mixin(UERegisterComponent!());
        
        int baseClassMember;
    }

    class Comp2: BaseComp
    {
        mixin(UERegisterComponent!());
        
        int i;
        bool b;
        UEComponent comp1;
        Comp1 comp1_;
        Comp1 compCheckNull;
        int[] intArr = [0,1];
        UEComponent[] compArr;
        int[2] intStatArr = [0,0];
        ubyte ub;
        ubyte[2] ubArr;
        
        enum LocalEnum{foo,bar}
        vec2 v;
        quat q;
        
        alias AliasInt = int;
        
        LocalEnum e=LocalEnum.bar;
        AliasInt ai=2;
        
        @NonSerialize
        int dont;
        
        //@Serialize
        //private int priv;
        private int bar;
    }

    UESceneNode n = new UESceneNode;
    UEEntity e = UEEntity.create("test",n);
    e.sceneNode.angles = vec3(90,0,0);
    UESerializer s;
    Comp1 comp1 = new Comp1();
    comp1.val = 50;
    Comp2 c = new Comp2();
    c.hideFlags = c.hideFlags.set(HideFlags.hideInInspector);
    c.compArr = [comp1,comp1,c];
    c.comp1 = comp1;
    c.v = vec2(10,20);
    c.ub = 2;
    c.q.y = 0.5f;
    c.i=2;
    c.ai=3;
    c.b = true;
    c.intArr = [1,2];
    c.ubArr[0] = 128;
    c.intStatArr = [3,4];
    c.baseClassMember = 42;
    c.dont = 1;
    c.e=Comp2.LocalEnum.foo;
    c._entity = e;
    c.comp1_ = comp1;

    c.serialize(s);

    auto serializeString = s.toString();

    writefln("string: \n'%s'",serializeString);

    Comp2 c2 = new Comp2();
    UEDeserializer d = UEDeserializer(serializeString);
    c2.deserialize(d);

    assert(d.findObject("UEEntity", to!string(e.instanceId)));
    assert(c2.i == c.i);
    assert(c2.ub == c.ub);
    assert(c2.ubArr[0] == c.ubArr[0]);
    assert(c2.sceneNode.angles.x == c.sceneNode.angles.x, format("%s != %s",c2.sceneNode.angles.x,c.sceneNode.angles.x));
    assert(c2.v == c.v, format("%s",c2.v));
    assert(c2.q.x.isNaN);
    assert(c2.q.y == c.q.y, format("%s",c2.q));
    assert(c2.b == c.b);
    assert(c2.intArr == c.intArr);
    assert(c2.intStatArr == c.intStatArr);
    assert(c2.ai == c.ai);
    assert(c2.e == c.e);
    assert(c2.baseClassMember == c.baseClassMember, format("%s != %s",c2.baseClassMember,c.baseClassMember));
    assert(c2.dont != c.dont);
    assert(c2._entity !is null);
    assert(c2._entity.name == "test");
    assert(c2.compArr.length == 3);
    assert(c2.compArr[0] == c2.compArr[1]);
    assert(c2.compArr[2] == c2);
    assert((cast(Comp1)c2.comp1).val == (cast(Comp1)c.comp1).val);
    assert(c2.comp1 is c2.comp1_);
    assert(c2.entity.instanceId == c.entity.instanceId, format("%s != %s", c2.entity.instanceId,c.entity.instanceId));

    // test genral private accessing
    assert( c.accessPrivate!(HideFlagSet)("_hideFlags").isSet(HideFlags.hideInInspector) );
}
