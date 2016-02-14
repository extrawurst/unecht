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
    package Tag content;

    ///
    public UUID[] blacklist;
    ///
    public UUID[] externals;

    mixin generateSerializeFunc!serializeMemberWithName;

    ///
    public void serializeObjectMember(T,M)(T obj, string name, ref M member, UECustomFuncSerialize!M customFunc=null)
        if(is(T : UEObject))
    {
        if(!content)
        {
            content = new Tag();
            content.name = "content";
        }

        serializeTo!(T,M)(obj, name, member, content, customFunc);
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

    private void serializeTo(T,M)(T v, string name, ref M member, Tag parent, UECustomFuncSerialize!M func=null)
    {
        auto componentTag = getTag(v.instanceId.toString(), Unqual!(T).stringof, parent);

        if(name in componentTag.all.tags)
            return;

        Tag memberTag = new Tag(componentTag);
        memberTag.name = name;

        if(func)
            func(member,this,memberTag);
        else
            serializeMember(member, memberTag);
    }
                                                            
    private bool isBlacklisted(in UUID id) const
    {
        import std.algorithm:countUntil;
        return countUntil(blacklist, id) != -1;
    }

    private bool isExternal(in UUID id) const
    {
        import std.algorithm:countUntil;
        return countUntil(externals, id) != -1;
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

            if(!isExternal(val.instanceId) && !getInstanceTag(instanceId))
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

    ///
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
    package Tag root;
    public UEObject[] externalObjects;
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

    public void addExternalObj(UEObject obj)
    {
        externalObjects ~= obj;
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

    ///
    public void deserializeObjectMember(T,M)(T obj, string uid, string membername, ref M member, UECustomFuncDeserialize!M customFunc=null)
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
            
            deserializeFromTag!(T,M)(obj, membername, member, tag, customFunc);
        }
    }

    ///
    public bool hasObjectId(string objectId)
    {
        return findObject(objectId) !is null;
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

    private void deserializeFromTag(T,M)(T obj, string membername, ref M member, Tag parent, UECustomFuncDeserialize!M customFunc=null)
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
            
        if(customFunc)
            customFunc(member, this, membertags[0]);
        else
            deserializeMember(member, membertags[0]);
    }

    private void deserializeFromMemberName(T)(ref T v, Tag tag, string membername)
    {
        auto memberTag = tag.all.tags[membername][0];
        assert(memberTag);
        
        deserializeMember(v, memberTag);
    }
    
    private void deserializeMember(T)(ref T val, Tag parent)
        if(is(T : UEObject))
    {
        if(parent.values.length == 0)
            return;
            
        assert(parent.values.length == 1, format("[%s] wrong value count %s",T.stringof,parent.values.length));

        const uid = parent.values[0].get!string;
        assert(uid.length > 0);

        auto r = findRef(uid);
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
        }
    }

    ///
    package UEObject findRef(string uid)
    {
        auto loaded = findLoadedRef(uid);
        if(loaded)
            return loaded;

        return findExternalRef(uid);
    }

    ///
    package UEObject findLoadedRef(string uid)
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

    ///
    package UEObject findExternalRef(string uid)
    {
        foreach(o; externalObjects)
        {
            if(o.instanceId.toString() == uid)
            {
                return o;
            }
        }

        return null;
    }

    ///
    package void storeLoadedRef(UEObject v, string uid)
    {
        assert(v !is null);

        assert(!findRef(uid));

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

///
alias UECustomFuncSerialize(T) = void function(ref T, ref UESerializer, Tag);
///
alias UECustomFuncDeserialize(T) = void function(ref T, ref UEDeserializer, Tag);

/// UDA to mark a type that contains custom serialization methods
struct CustomSerializer
{
    string serializerTypeName;
}
