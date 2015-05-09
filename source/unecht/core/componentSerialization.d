﻿module unecht.core.componentSerialization;

import std.conv;
import std.traits:isPointer,Unqual,BaseClassesTuple;

import unecht.core.component;
import unecht.meta.uda;
import unecht.core.entity;
import sdlang;

import std.string:format;

enum isSerializerBaseType(T) = //is( T : Value        ) ||
    is( T : bool         ) ||
        is( T : string       ) ||
        is( T : dchar        ) ||
        is( T : int          ) ||
        is( T : long         ) ||
        is( T : float        ) ||
        is( T : double       ) ||
        is( T : real         ) ||
        //is( T : Date         ) ||
        //is( T : DateTimeFrac ) ||
        //is( T : SysTime      ) ||
        //is( T : DateTimeFracUnknownZone ) ||
        //is( T : Duration     ) ||
        is( T : ubyte[]      )
        //is( T : typeof(null)
        ;

struct SerializerUID
{
    ubyte[20] nameHash;
    size_t refId;
}

///
struct UESerializer
{
    SerializerUID[] alreadySerialized;

    Tag dependencies;
    Tag content;
    bool rootWritten=false;

    void serialize(T)(T v)
        if(is(T:UEComponent))
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

    private bool isCachedRefElseCache(T)(T v,ref size_t refId)
    {
        import std.algorithm:countUntil;
        import std.digest.sha;

        SerializerUID uid;
        uid.refId = refId = cast(size_t)cast(void*)v;
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
        size_t refId;
        if(isCachedRefElseCache(v,refId))
            return;

        Tag componentTag = new Tag(parent);
        componentTag.add(new Attribute("uid", Value(to!string(refId))));
        componentTag.name = Unqual!(T).stringof;

        //pragma (msg, "----------------------------------------");
        //pragma (msg, T.stringof);
        //pragma (msg, __traits(derivedMembers, T));
        
        foreach(m; __traits(derivedMembers, T))
        {
            enum isMemberVariable = is(typeof(() {
                        __traits(getMember, v, m) = __traits(getMember, v, m).init;
                    }));
            
            enum isNonStatic = !is(typeof(mixin("&T."~m)));

            //pragma(msg, .format("- %s (%s,%s)",m,isMemberVariable,isNonStatic));

            static if(isMemberVariable && isNonStatic) {

                enum isPublic = __traits(getProtection, __traits(getMember, v, m)) == "public";

                enum hasSerializeUDA = hasUDA!(mixin("T."~m), Serialize);
                
                enum hasNonSerializeUDA = hasUDA!(mixin("T."~m), NonSerialize);

                //pragma(msg, .format("> %s (%s,%s,%s)",m,isPublic,hasSerializeUDA,hasNonSerializeUDA));
                
                static if((isPublic || hasSerializeUDA) && !hasNonSerializeUDA)
                {
                    //pragma(msg, "-> "~m);
                    
                    Tag memberTag = new Tag(componentTag);
                    memberTag.name = m;
                    
                    serializeMember(__traits(getMember, v, m), memberTag);
                }
            }
        }
    }

    private void serializeTo(UEEntity v, Tag parent)
    {
        size_t refId;
        if(isCachedRefElseCache(v,refId))
            return;

        Tag componentTag = new Tag(parent);
        componentTag.add(new Attribute("uid", Value(to!string(refId))));
        componentTag.name = "UEEntity";

        //TODO: serialize all relevant members
        {
            Tag memberTag = new Tag(componentTag);
            memberTag.name = "name";
            serializeMember(v.name, memberTag);
        }
        {
            Tag memberTag = new Tag(componentTag);
            memberTag.name = "children";
            serializeMember(v.components, memberTag);
        }
    }
    
    void serializeMember(T)(T val, Tag parent)
        if(is(T : UEComponent))
    {
        if(val !is null)
        {
            val.serialize(this);

            auto classId = cast(size_t)cast(void*)val;
            parent.add(Value(to!string(classId)));
        }
    }

    void serializeMember(UEEntity val, Tag parent)
    {
        if(val !is null)
        {
            serializeTo(val,dependencies);
            
            auto classId = cast(size_t)cast(void*)val;
            parent.add(Value(to!string(classId)));
        }
    }

    static void serializeMember(T)(in ref T val, Tag parent)
        if(is(T == enum))
    {
        parent.add(Value(cast(int)val));
    }

    static void serializeMember(T)(T val, Tag parent)
        if(isPointer!T)
    {
        static assert(false, "TODO");
    }

    static void serializeMember(T)(T[] val, Tag parent)
        if(isSerializerBaseType!T && !is(T : char))
    {
        foreach(v; val)
        {
            auto t = new Tag(parent);
            serializeMember(v,t);
        }
    }

    void serializeMember(T)(T val, Tag parent)
        if(is(T : Arr[],Arr : UEComponent))
    {
        foreach(v; val)
        {
            auto t = new Tag(parent);
            serializeMember(v,t);
        }
    }

    static void serializeMember(T)(T val, Tag parent)
        if(is(T == struct) && __traits(isPOD,T))
    {
        /+Tag componentTag = new Tag(parent);

        foreach(m; __traits(allMembers, T))
        {
            enum isMemberVariable = is(typeof(() {
                        __traits(getMember, val, m) = __traits(getMember, val, m).init;
                    }));
            
            static if(isMemberVariable) {
                serializeMember(__traits(getMember, val, m), componentTag);
            }
        }+/
    }

    static void serializeMember(T)(T val, Tag parent)
        if( isSerializerBaseType!T && !is(T == enum) )
    {
        parent.add(Value(val));
    }

    string toString() 
    {
        auto root = new Tag;

        root.add(content);
        root.add(dependencies);

        return root.toSDLDocument();
    }
}

/// UDA to mark serialization fields
struct Serialize{}
/// UDA to mark serialization fields to not be serialized
struct NonSerialize{}

unittest
{
    import std.stdio;
    import unecht;
    import unecht.core.components.sceneNode;

    class Comp1: UEComponent
    {
        mixin(UERegisterComponent!());
    }

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
        Comp1 comp1 = new Comp1;
        Comp1 comp1_;
        Comp1 compCheckNull;
        int[] intArr = [0,1];
        
        enum LocalEnum{foo,bar}
        //struct LocalStruct{}
        
        alias AliasInt = int;
        
        LocalEnum e=LocalEnum.bar;
        AliasInt ai=2;
        
        @NonSerialize
        int dont;
        
        @Serialize
        private int priv;
        private int bar;
    }

    UESceneNode n = new UESceneNode;
    UEEntity e = UEEntity.create("test",n);
    UESerializer s;
    Comp2 c = new Comp2();
    c._entity = e;
    c.comp1_ = c.comp1;

    c.serialize(s);
    writefln("%s",s.toString());
}