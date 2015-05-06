module unecht.core.componentSerialization;

import std.conv;
import std.traits:isPointer,Unqual,BaseClassesTuple;

import unecht.core.component;
import unecht.meta.uda;
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

    Tag dependencies = new Tag;
    Tag content = new Tag;
    bool rootWritten=false;

    void serialize(T)(T v)
        if(is(T:UEComponent))
    {
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

    private void serializeTo(T)(T v, Tag parent)
    {
        import std.algorithm:countUntil;
        import std.digest.sha;

        SerializerUID uid;
        uid.refId = cast(size_t)cast(void*)v;
        uid.nameHash = sha1Of(Unqual!(T).stringof);

        if(alreadySerialized.countUntil(uid) != -1)
            return;
        alreadySerialized ~= uid;

        Tag componentTag = new Tag(parent);
        componentTag.add(new Attribute("uid", Value(to!string(uid.refId))));
        componentTag.name = Unqual!(T).stringof;

        pragma (msg, "----------------------------------------");
        pragma (msg, T.stringof);
        //pragma (msg, __traits(derivedMembers, T));
        
        foreach(m; __traits(derivedMembers, T))
        {
            enum isMemberVariable = is(typeof(() {
                        __traits(getMember, v, m) = __traits(getMember, v, m).init;
                    }));
            
            enum isNonStatic = !is(typeof(mixin("&T."~m)));

            pragma(msg, .format("- %s (%s,%s)",m,isMemberVariable,isNonStatic));

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

    void serializeMember(T)(T val, Tag parent)
        if(is(T : UEComponent))
    {
        val.serialize(this);

        auto classId = cast(size_t)cast(void*)val;
        parent.add(Value(to!string(classId)));
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

    static void serializeMember(T)(T val, Tag parent)
        if(is(T : Arr[],Arr : UEComponent))
    {
        //parent.addValue(Value(cast(void*)val));
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

    UESerializer s;
    Comp2 c = new Comp2();
    c.comp1_ = c.comp1;

    c.serialize(s);
    writefln("%s",s.toString());
}