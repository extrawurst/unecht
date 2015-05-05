module unecht.core.componentSerialization;

import std.conv;
import std.traits:isPointer;

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
    Tag root = new Tag();

    void serialize(T)(T v)
        if(is(T:UEComponent))
    {
        Tag componentTag = new Tag(root);
        componentTag.name = T.stringof;

        pragma (msg, T.stringof~": ----------------------------------------");
        pragma (msg, __traits(derivedMembers, T));
        
        foreach(m; __traits(derivedMembers, T))
        {
            enum isMemberVariable = is(typeof(() {
                        __traits(getMember, v, m) = __traits(getMember, v, m).init;
                    }));

            enum isNonStatic = !is(typeof(mixin("&T."~m)));
            
            static if(isMemberVariable && isNonStatic) {
            
                enum isPublic = __traits(getProtection, __traits(getMember, v, m)) == "public";

                enum hasSerializeUDA = hasUDA!(mixin("T."~m), Serialize);

                enum hasNonSerializeUDA = hasUDA!(mixin("T."~m), NonSerialize);

                static if((isPublic || hasSerializeUDA) && !hasNonSerializeUDA)
                {
                    pragma(msg, "> "~m);

                    serialize(__traits(getMember, v, m), componentTag);
                }
            }
        }
    }

    static void serialize(T)(in T val, Tag parent)
        if(is(T : UEComponent))
    {
        //parent.addValue(Value(cast(void*)val));
    }

    static void serialize(T)(in ref T val, Tag parent)
        if(is(T : UEComponent))
    {
        //parent.addValue(Value(cast(void*)val));
    }

    static void serialize(T)(in ref T val, Tag parent)
        if(is(T == enum))
    {
        //parent.addValue(Value(cast(void*)val));
    }

    static void serialize(T)(T val, Tag parent)
        if(isPointer!T)
    {
        //parent.addValue(Value(cast(void*)val));
    }

    static void serialize(T)(T[] val, Tag parent)
        if(isSerializerBaseType!T && !is(T : char))
    {
        //parent.addValue(Value(cast(void*)val));
    }

    static void serialize(T)(in ref T val, Tag parent)
        if(is(T : Arr[],Arr : UEComponent))
    {
        //parent.addValue(Value(cast(void*)val));
    }

    static void serialize(T)(T val, Tag parent)
        if(is(T == struct) && __traits(isPOD,T))
    {
        Tag componentTag = new Tag(parent);

        foreach(m; __traits(allMembers, T))
        {
            enum isMemberVariable = is(typeof(() {
                        __traits(getMember, val, m) = __traits(getMember, val, m).init;
                    }));
            
            static if(isMemberVariable) {
                serialize(__traits(getMember, val, m), componentTag);
            }
        }
    }

    static void serialize(T)(T val, Tag parent)
        if( isSerializerBaseType!T && !is(T == enum) )
    {
        parent.add(Value(val));
    }

    string toString() 
    {
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

    class BaseComp: UEComponent
    {
        mixin(UERegisterComponent!());
    }

    UESerializer s;
    BaseComp c = new BaseComp();

    c.serialize(s);
    writefln("%s",c.toString());
}

/+
unittest
{   
    import std.stdio;
    import unecht;

    class TestCompBase : UEComponent
    {
        mixin(UERegisterComponent!());

        bool base;
    }

    final class TestComp : TestCompBase
    {
        mixin(UERegisterComponent!());
     
        enum LocalEnum{foo,bar}
        struct LocalStruct{}
        
        alias AliasInt = int;

        LocalEnum e=LocalEnum.bar;
        bool foo;
        float baz=0;

        @Serialize
        private int priv;
        private int bar;
        
        void otherMethod(int a){}
        bool testMethod(T)(T v){}
        static bool testMethod2(T)(T v){}
    }
    
    TestComp tc = new TestComp();
    Tag root = new Tag();
    
    tc.serialize(root);
    //writefln("'%s'",root.toSDLDocument);
    
    assert(root.toSDLDocument == "super {\n\tsuper {\n\t\tenabled true\n\t}\n\tbase false\n}\ne 1\nfoo false\nbaz 0F\npriv 0\n");
}

unittest
{   
    import std.stdio;
    import unecht;
    
    final class TestComp1 : UEComponent
    {
        mixin(UERegisterComponent!());
        
        bool foo;
    }
    
    final class TestComp2 : UEComponent
    {
        mixin(UERegisterComponent!());
        
        TestComp1 comp;
    }
    
    auto tc1 = new TestComp1();
    auto tc2 = new TestComp2();
    tc2.comp = tc1;

    Tag root = new Tag();

    tc2.serialize(root);
    //writefln("'%s'",root.toSDLDocument);
    
    assert(root.toSDLDocument == "super {\n\tenabled true\n}\ncomp {\n\tsuper {\n\t\tenabled true\n\t}\n\tfoo false\n}\n");
}

unittest
{   
    import std.stdio;
    import unecht;
    
    final class TestComp1 : UEComponent
    {
        mixin(UERegisterComponent!());
    }
    
    final class TestComp2 : UEComponent
    {
        mixin(UERegisterComponent!());
        
        TestComp1[] comps;
    }
    
    auto tc1 = new TestComp1();
    auto tc2 = new TestComp2();
    tc2.comps = [tc1, tc1];
    
    Tag root = new Tag();
    
    tc2.serialize(root);
    writefln("'%s'",root.toSDLDocument);
    
    //assert(root.toSDLDocument == "super {\n\tenabled true\n}\ncomp {\n\tsuper {\n\t\tenabled true\n\t}\n\tfoo false\n}\n");
}+/