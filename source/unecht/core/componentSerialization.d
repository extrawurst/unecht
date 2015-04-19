module unecht.core.componentSerialization;

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
        static if(isSerializationMemberName!MEM && !isNestedType!MEM)
        {
            static if(__traits(getProtection, mixin(TdotMember)) == "public")
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
        //pragma (msg, T.stringof~": ----------------------------------------");
        //pragma (msg, __traits(derivedMembers, T));
        import std.typetuple:Filter;
        foreach(m; Filter!(isSerializable, __traits(derivedMembers, T)))
        {
            alias memberType = typeof(mixin("v."~m));
            
            Tag memberTag = new Tag(parent);
            memberTag.name = m;
            
            static if(is(memberType == class) || is(memberType == struct) || is(memberType == function) || is(memberType == delegate))
            {
                //pragma(msg, "struct or class: "~m);
            }
            else static if(isArray!(memberType))
            {
                //pragma(msg, "array: "~m);
            }
            else static if(isPointer!(memberType))
            {
                //pragma(msg, "pointer: "~m);
            }
            else static if(is(memberType == enum))
            {
                //pragma(msg, "enum: "~m);
            }
            else
            {
                //pragma(msg, "other:"~m);
                memberTag.add(Value(mixin("v."~m)));
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
    import sdlang;
    import unecht;
    
    final class TestComp : UEComponent
    {
        mixin(UERegisterComponent!());
        
        struct LocalStruct{}
        
        alias AliasInt = int;
        
        bool foo;
        float baz=0;
        private int bar;
        
        void otherMethod(int a){}
        bool testMethod(T)(T v){}
        static bool testMethod2(T)(T v){}
    }
    
    TestComp tc = new TestComp();
    Tag root = new Tag();
    
    //writefln("\nSERIALIZATION TESTING:\n");
    
    TestComp.serialization.serialize(tc,root);
    writefln("%s",root.toSDLDocument);
    
    //assert(UECamera.serialization.serialize(cam) == "UECamera");
}