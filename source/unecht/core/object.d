module unecht.core.object;

public import unecht.core.hideFlags;
import unecht.core.componentSerialization;

///
abstract class UEObject
{
    import std.uuid;

    ///
    this()
    {
        //TODO: find out why this is called at compile time (#87)
        if(!__ctfe)
        {
            instanceId = randomUUID();
        }
    }
    
    //TODO: see #79
    @Serialize private
    {
        public UUID instanceId;
        HideFlagSet _hideFlags;
    }

    ///
    public void hideFlags(HideFlagSet v) { _hideFlags = v; }
    ///
    public HideFlagSet hideFlags() const { return _hideFlags; }

    final public ref T accessPrivate(T)(string memberName)
    {
        auto memberOffset = this.memberOffset(memberName);

        return *cast(T*)(cast(ubyte*)this + memberOffset);
    }

    protected size_t memberOffset(string memberName)
    {
        import unecht.meta.uda;

        alias T = typeof(this);
        auto v= this;

        pragma (msg, "----------------------------------------");
        pragma (msg, T.stringof);
        pragma (msg, __traits(derivedMembers, T));

        size_t[string] offsets;

        foreach(m; __traits(derivedMembers, T))
        {
            enum isMemberVariable = is(typeof(() {
                        __traits(getMember, v, m) = __traits(getMember, v, m).init;
                    }));
            
            enum isMethod = is(typeof(() {
                        __traits(getMember, v, m)();
                    }));
            
            enum isNonStatic = !is(typeof(mixin("&T."~m)));
            
            pragma(msg, .format("- %s (%s,%s,%s)",m,isMemberVariable,isNonStatic,isMethod));
            
            static if(isMemberVariable && isNonStatic && !isMethod) {
                
                enum isPublic = __traits(getProtection, __traits(getMember, v, m)) == "public";
                
                enum hasSerializeUDA = hasUDA!(mixin("T."~m), Serialize);
                
                //pragma(msg, .format("> %s (%s,%s,%s)",m,isPublic,hasSerializeUDA,hasNonSerializeUDA));
                
                static if(!isPublic && hasSerializeUDA)
                {
                    pragma(msg, "-> "~m);

                    offsets[m] = __traits(getMember, v, m).offsetof;
                }
            }
        }

        auto pOffset = memberName in offsets;
        if(pOffset) return *pOffset;
        else return size_t.max;
    }

    version(UEIncludeEditor)abstract @property string typename();

    void serialize(ref UESerializer serializer) 
    {
        serializer.serialize(this);
    }
    
    void deserialize(ref UEDeserializer serializer, string uid=null) 
    {
        serializer.deserialize(this, uid);
    }
    
    ///TBD
    static UEObject instantiate(UEObject obj)
    {
        //TODO:
        return null;
    }
}

unittest
{
    import unecht;

    class Foo : UEObject
    {
        mixin(UERegisterComponent!());
    }

    Foo foo = new Foo();
    assert(foo.memberOffset("_hideFlags") == foo._hideFlags.offsetof);
}