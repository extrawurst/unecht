module unecht.core.serialization.serializer;

import std.conv;
import std.uuid;
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
                
                //pragma(msg, .format("> %s (%s,%s,%s)",m,isPublic,hasSerializeUDA,hasNonSerializeUDA));
                
                static if(isPublic || hasSerializeUDA)
                {
                    //pragma(msg, "-> "~m);

                    Func(__traits(getMember, v, m), tag, m);
                }
            }
        }
    }
}

///
struct UESerializer
{
    //TODO: make package-protected once this module moved to serialization package
    public Tag content;

    public UUID[] blacklist;

    mixin generateSerializeFunc!serializeMemberWithName;

    ///
    public void serializeObjectMember(T,M, string custom=null)(T obj, string name, ref M member)
        if(is(T : UEObject))
    {
        if(!content)
        {
            content = new Tag();
            content.name = "content";
        }

        serializeTo!(T,M,custom)(obj, name, member, content);
    }

    private void serializeMemberWithName(T)(T v, Tag tag, string membername)
    {
        Tag memberTag = new Tag(tag);
        memberTag.name = membername;
        
        serializeMember(v, memberTag);
    }

    private Tag getTag(string id, string type, Tag parent)
    {
        Tag idTag = getInstanceTag(id);

        if(idTag is null)
        {
            idTag = new Tag(parent);
            idTag.name = "obj";
            idTag.add(new Attribute("id", Value(id)));
        }

        Tag typeTag;

        if(!(type in idTag.all.tags))
        {
            typeTag = new Tag(idTag);
            typeTag.name = type;
        }
        else
            typeTag = idTag.all.tags[type][0];

        return typeTag;
    }

    private void serializeTo(T,M, string custom=null)(T v, string name, ref M member, Tag parent)
    {
        auto componentTag = getTag(v.instanceId.toString(), Unqual!(T).stringof, parent);

        if(name in componentTag.all.tags)
            return;

        Tag memberTag = new Tag(componentTag);
        memberTag.name = name;

        static if(custom == null)
        {
            serializeMember(member, memberTag);
        }
        else
        {
            mixin(format("%s.serialize(member,this,memberTag);",custom));
        }
    }
                                                            
    private bool isBlacklisted(in UUID id) const
    {
        import std.algorithm:countUntil;
        return countUntil(blacklist, id) != -1;
    }

    private Tag getInstanceTag(string id)
    {
        foreach(o; content.all.tags)
        {
            auto attribute = o.attributes["id"][0];
            if(attribute.value.get!string == id)
                return o;
        }

        return null;
    }

    private void serializeMember(T)(T val, Tag parent)
        if(is(T : UEObject))
    {
        if(val !is null)
        {
            if(isBlacklisted(val.instanceId) || val.hideFlags.isSet(HideFlags.dontSaveInScene))
            {
                parent.remove();
                return;
            }

            string instanceId = val.instanceId.toString();

            if(!getInstanceTag(instanceId))
                val.serialize(this);
                
            parent.add(Value(instanceId));
            parent.add(new Attribute("type", Value(typeid(val).toString())));
        }
    }

    private static void serializeMember(T)(in ref T val, Tag parent)
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

    private static void serializeMember(T)(T val, Tag parent)
        if( isSerializerBaseType!T && !is(T == enum) && !__traits(isStaticArray,T))
    {
        static if(isExactSerializerBaseType!T)
            parent.add(Value(val));
        else
            parent.add(Value(to!string(val)));
    }

    public string toString()
    {
        auto root = new Tag;

        root.add(content);

        return root.toSDLDocument();
    }
}

///
struct UEDeserializer
{
    import unecht.core.components.sceneNode;

    struct LoadedObject
    {
        UEObject o;
        string uid;
    }

    private Tag content;
    public Tag root;
    private bool rootRead;
    public LoadedObject[] objectsLoaded;

    mixin generateSerializeFunc!deserializeFromMemberName;

    ///
    this(string input)
    {
        import std.stdio;
        root =  parseSource(input);

        content = root.all.tags["content"][0];
        assert(content !is null);
    }

    /// renew each id of every loaded object
    public void createNewIds()
    {
        foreach(o; objectsLoaded)
        {
            o.o.newInstanceId();
        }
    }

    ///
    public auto deserializeFirst(T)()
        if(is(T:UEObject))
    {
        auto result = new T;
        storeLoadedRef(result, findFirstID);
        result.deserialize(this, findFirstID);
        return result;
    }

    private string findFirstID()
    {
        auto contentRoot = content.all.tags.front;

        return contentRoot.attributes["id"][0].value.get!string; 
    }

    public void deserializeObjectMember(T,M,string custom=null)(T obj, string uid, string membername, ref M member)
        if(is(T : UEObject))
    {
        if(uid is null || uid.length == 0)
        {
            assert(false);
        }
        else
        {
            auto tag = findObject(uid);
            assert(tag, format("obj not found: '%s' (%s)",T.stringof, uid));

            if(!findObject(uid))
                storeLoadedRef(obj,uid);
            
            deserializeFromTag!(T,M,custom)(obj, membername, member, tag);
        }
    }

    private Tag findObject(string objectId)
    {
        auto objects = content.all.tags["obj"];
        foreach(Tag o; objects)
        {
            auto uid = o.attributes["id"];

            if(!uid.empty && uid[0].value == objectId)
            {
                return o;
            }
        }

        return null;
    }

    private void deserializeFromTag(T,M,string custom=null)(T obj, string membername, ref M member, Tag parent)
    {
        auto tags = parent.all.tags[Unqual!(T).stringof];

        if(tags.empty)
            return;

        auto typeTag = tags[0];

        if(!(membername in typeTag.all.tags))
            return;

        auto membertags = typeTag.all.tags[membername];

        if(membertags.empty)
            return;

        static if(custom == null)
        {
            deserializeMember(member, membertags[0]);
        }
        else
        {
            mixin(format("%s.deserialize(member,this,membertags[0]);",custom));
        }
    }

    private void deserializeFromMemberName(T)(ref T v, Tag tag, string membername)
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
            auto typename = parent.attributes["type"][0].value.get!string;
            val = cast(T)Object.factory(typename);
            assert(val, format("could not create: %s",typename));
            
            storeLoadedRef(val,uid);

            val.deserialize(this, uid);

            static if(is(T : UEComponent))
                val.onCreate();
        }
    }

    //TODO: make package once it is in serializer package
    public UEObject findLoadedRef(string uid)
    {
        alias objArray = objectsLoaded;

        foreach(o; objArray)
        {
            if(o.uid == uid)
            {
                return o.o;
            }
        }

        return null;
    }

    public void storeLoadedRef(UEObject v, string uid)
    {
        assert(v !is null);

        assert(!findLoadedRef(uid));

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

/// UDA to mark a type that contains custom serialization methods
struct CustomSerializer
{
    string serializerTypeName;
}

version(unittest):
import unecht;

struct CustomTestSerializer
{
    static void serialize(ref CustomSerializeTestStruct v, ref UESerializer serializer, Tag parent)
    {
        serializer.serializeMember(v.foobar, parent);
    }
                        
    static void deserialize(ref CustomSerializeTestStruct v, ref UEDeserializer serializer, Tag parent)
    {
        serializer.deserializeMember(v.foobar, parent);
    }
}
                    
struct CustomSerializeTestStruct
{
    int ignoreTest = 1;
    private int foobar = 2;
}

class Comp1: UEComponent
{
    mixin(UERegisterObject!());

    @Serialize
    int val;
}

class BaseComp: UEComponent
{
    mixin(UERegisterObject!());

    @Serialize
    int baseClassMember;
}

class Comp2: BaseComp
{
    mixin(UERegisterObject!());

    @Serialize{
    int i;
    bool b;
    float inf = 1;
    UEComponent comp1;
    Comp1 compHide;
    Comp1 comp1_;
    Comp1 compCheckNull;
    int[] intArr = [0,1];
    UEComponent[] compArr;
    int[2] intStatArr = [0,0];
    ubyte ub;
    ubyte[2] ubArr;
    @CustomSerializer("CustomTestSerializer")
    CustomSerializeTestStruct customSer;
    
    enum LocalEnum{foo,bar}
    vec2 v;
    quat q;
    
    alias AliasInt = int;
    
    LocalEnum e=LocalEnum.bar;
    AliasInt ai=2;
    
    private int priv;
    }

    int dont;
}

unittest
{
    import std.stdio;
    import unecht.core.components.sceneNode;

    UESceneNode n = new UESceneNode;
    n.hideFlags.set(HideFlags.dontSaveInScene);
    UEEntity e = UEEntity.create("test",n);
    e.sceneNode.angles = vec3(90,0,0);
    Comp1 comp1 = new Comp1();
    comp1.val = 50;
    Comp2 c = e.addComponent!Comp2;
    c.hideFlags = c.hideFlags.set(HideFlags.hideInInspector);
    c.compArr = [comp1,comp1,c];
    c.comp1 = comp1;
    c.compHide = e.addComponent!Comp1;
    c.compHide.val = 42;
    c.compHide.hideFlags.set(HideFlags.dontSaveInScene);
    c.v = vec2(10,20);
    c.ub = 2;
    c.q.y = 0.5f;
    c.inf = float.infinity;
    c.i=2;
    c.ai=3;
    c.b = true;
    c.intArr = [1,2];
    c.ubArr[0] = 128;
    c.intStatArr = [3,4];
    c.baseClassMember = 42;
    c.dont = 1;
    c.e=Comp2.LocalEnum.foo;
    c.comp1_ = comp1;
    c.customSer.ignoreTest = -1;
    c.customSer.foobar = -1;

    UESerializer s;
    c.serialize(s);

    auto serializeString = s.toString();

    import std.file:write;
    write("serializationTest.txt", serializeString);

    UEDeserializer d = UEDeserializer(serializeString);
    Comp2 c2 = d.deserializeFirst!Comp2;
   
    assert(d.findObject(to!string(e.instanceId)));
    assert(c2.i == c.i, format("%s != %s",c2.i,c.i));
    assert(c2.hideFlags == c.hideFlags,format("%s != %s",c2.hideFlags,c.hideFlags));
    assert(c2.instanceId == c.instanceId);
    assert(c2.ub == c.ub);
    assert(c2.ubArr[0] == c.ubArr[0]);
    assert(c2.sceneNode.angles.x == c.sceneNode.angles.x, format("%s != %s",c2.sceneNode.angles.x,c.sceneNode.angles.x));
    assert(c2.v == c.v, format("%s",c2.v));
    assert(c2.q.x.isNaN);
    assert(c2.q.y == c.q.y, format("%s",c2.q));
    assert(c2.inf.isInfinity, format("%s != float.isInfinity",c2.inf));
    assert(c2.b == c.b);
    assert(c2.intArr == c.intArr);
    assert(c2.intStatArr == c.intStatArr);
    assert(c2.ai == c.ai);
    assert(c2.e == c.e);
    assert(c2.baseClassMember == c.baseClassMember, format("%s != %s",c2.baseClassMember,c.baseClassMember));
    assert(c2.dont != c.dont);
    assert(c2.customSer.ignoreTest == CustomSerializeTestStruct.init.ignoreTest);
    assert(c2.customSer.foobar == c.customSer.foobar);
    assert(c2.entity !is null);
    assert(c2.entity.name == "test");
    assert(c2.compArr.length == 3);
    assert(c2.compArr[0] == c2.compArr[1]);
    assert(c2.compArr[2] is c2, format("%s != %s",c2.compArr[2].instanceId,c2.instanceId));
    assert((cast(Comp1)c2.comp1).val == (cast(Comp1)c.comp1).val);
    assert(c2.comp1 is c2.comp1_);
    assert(c2.entity.instanceId == c.entity.instanceId, format("%s != %s", c2.entity.instanceId,c.entity.instanceId));
}
