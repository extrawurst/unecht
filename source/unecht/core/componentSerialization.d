module unecht.core.componentSerialization;

import std.conv;
import std.traits:isPointer,Unqual;

import unecht.core.component;
import unecht.meta.uda;
import sdlang;

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

///
struct UESerializer
{
    size_t[] alreadySerialized;

    Tag dependencies = new Tag;
    Tag content = new Tag;

    void serialize(T)(T v)
        if(is(T:UEComponent))
    {
        dependencies.name = "dependencies";
        content.name = "content";

        serializeTo(v, content);
    }

    private void serializeTo(T)(T v, Tag parent)
    {
        import std.algorithm:countUntil;
        
        auto classId = cast(size_t)cast(void*)v;
        if(alreadySerialized.countUntil(classId) != -1)
            return;
        alreadySerialized ~= classId;
        
        Tag componentTag = new Tag(parent);
        componentTag.add(new Attribute("uid", Value(to!string(classId))));
        componentTag.name = Unqual!(T).stringof;
        
        //pragma (msg, T.stringof~": ----------------------------------------");
        //pragma (msg, __traits(derivedMembers, T));
        
        foreach(m; __traits(derivedMembers, T))
        {
            enum isMemberVariable = is(typeof(() {
                        __traits(getMember, v, m) = __traits(getMember, v, m).init;
                    }));
            
            enum isNonStatic = !is(typeof(mixin("&T."~m)));

            //pragma(msg, "- "~m);

            static if(isMemberVariable && isNonStatic) {

                //pragma(msg, "> "~m);

                enum isPublic = __traits(getProtection, __traits(getMember, v, m)) == "public";
                
                enum hasSerializeUDA = hasUDA!(mixin("T."~m), Serialize);
                
                enum hasNonSerializeUDA = hasUDA!(mixin("T."~m), NonSerialize);
                
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

    void serializeMember(T)(inout T val, Tag parent)
        if(is(T : UEComponent))
    {
        serializeTo(val, dependencies);

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
        //parent.addValue(Value(cast(void*)val));
    }

    static void serializeMember(T)(T[] val, Tag parent)
        if(isSerializerBaseType!T && !is(T : char))
    {
        //parent.addValue(Value(cast(void*)val));
    }

    static void serializeMember(T)(in ref T val, Tag parent)
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

    class Comp2: UEComponent
    {
        mixin(UERegisterComponent!());
    }

    class BaseComp: UEComponent
    {
        mixin(UERegisterComponent!());

        int i;
        bool b;
        Comp2 base = new Comp2;

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
    BaseComp c = new BaseComp();

    s.serialize(c);
    writefln("%s",s.toString());
}