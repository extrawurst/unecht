module unecht.core.componentSerialization;

import std.conv;

import unecht.core.component;
import unecht.meta.uda;

///
struct Serialize{}

///
private static void serializeBase(T)(T v, Tag parent)
{
    //pragma(msg, "other:"~m);
    parent.add(Value(v));
}

///
private static void serializeType(T)(T v, Tag parent)
    if (is(T : UEComponent))
{
    //pragma(msg, "UEComponent: ");
    v.serialize(parent);
}

///
private static void serializeType(T)(T v, Tag parent)
    if (is(T : UEComponent) == false)
{
    //TODO:
    //pragma(msg, "UEComponent: ");
}

///
static struct UESerialization(T)
{
    import sdlang;
    import std.traits;
    
    template isSerializationMemberName(string MEM)
    {
        enum isSerializationMemberName = 
            (MEM != T.stringof) && 
                (MEM != "this") && 
                (MEM != "T") && 
                (MEM != "Monitor") && 
                (MEM != "serialization");
    }
    
    template isAnyFunction(alias MEM)
    {
        enum isAnyFunction =  __traits(isVirtualFunction, mixin("T."~MEM)) || 
            __traits(isStaticFunction, mixin("T."~MEM)) ||
                __traits(isOverrideFunction, mixin("T."~MEM)) ||
                __traits(isFinalFunction, mixin("T."~MEM)) ||
                __traits(isVirtualMethod, mixin("T."~MEM));
    }
    
    template isTemplate(alias MEM)
    {
        enum isTemplate =  is(typeof(mixin("T."~MEM)) == void);
    }
    
    template isNestedType(string MEM)
    {
        //TODO: more base types for the cases of aliases
        enum isNestedType = mixin("is(T."~MEM~" == enum)") || 
            mixin("is(T."~MEM~" == struct)") || 
                mixin("is(T."~MEM~" : int)");
    }
    
    template isNonStatic(string MEM)
    {
        //cannot take address of non-statics
        enum isNonStatic = !is(typeof(mixin("&T."~MEM)));
    }
    
    template isSerializable(alias MEM)
    {
        enum TdotMember="T."~MEM;
        enum compiles = __traits(compiles, mixin(TdotMember)); //NOTE: compiler bug: when removing this it wont compile under dmd<2.067
        static if(isSerializationMemberName!MEM && !isNestedType!MEM && __traits(compiles, mixin(TdotMember)))
        {
            enum protection=__traits(getProtection, mixin(TdotMember));
            enum hasSerializeUDA = hasUDA!(mixin(TdotMember),Serialize);
            static if(protection == "public" || hasSerializeUDA)
            {
                static if(!isAnyFunction!(MEM) && !isTemplate!MEM)
                {
                    enum isSerializable = isNonStatic!MEM;
                }
                else
                    enum isSerializable = false;
            }
            else
                enum isSerializable = false;
        }
        else 
            enum isSerializable = false;
    }
    
    alias aliasHelper(alias T) = T;
    alias aliasHelper(T) = T;
    
    static void serialize(T v, Tag parent)
    {
        pragma (msg, T.stringof~": ----------------------------------------");
        pragma (msg, __traits(derivedMembers, T));
        import std.typetuple:Filter;
        foreach(m; Filter!(isSerializable, __traits(derivedMembers, T)))
        {
            pragma(msg, "> "~m);

            alias memberType = typeof(mixin("v."~m));
            
            Tag memberTag = new Tag(parent);
            memberTag.name = m;
            
            static if(is(memberType == class) || is(memberType == struct) || is(memberType == function) || is(memberType == delegate))
            {
                serializeType!memberType(mixin("v."~m),memberTag);
            }
            else static if(isArray!(memberType))
            {
                pragma(msg, "array: "~m);
                mixin("foreach(i, c; v." ~m~ ") { Tag childTag = new Tag(memberTag); childTag.name=to!string(i); c.serialize(childTag); }");
            }
            else static if(isPointer!(memberType))
            {
                //pragma(msg, "pointer: "~m);
                memberTag.add(Value("pointers not implemented yet!"));
            }
            else static if(is(memberType == enum))
            {
                //TODO: support other enum base types
                //pragma(msg, "enum: "~m);
                memberTag.add(Value(cast(int)mixin("v."~m)));
            }
            else
            {
                serializeBase!memberType(mixin("v."~m),memberTag);
            }
        }
    }
    
    static void deserialize(ref T v, string source)
    {
        //TODO:
    }
}

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
}