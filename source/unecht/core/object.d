module unecht.core.object;

public import unecht.core.hideFlags;
import unecht.core.componentSerialization;
import unecht.meta.uda;

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
            newInstanceId();
        }
    }

    @Serialize private
    {
        UUID _instanceId;
        HideFlagSet _hideFlags;
    }

    ///
    public void hideFlags(HideFlagSet v) { _hideFlags = v; }
    ///
    public ref HideFlagSet hideFlags() { return _hideFlags; }
    ///
    public UUID instanceId() const { return _instanceId; }
    ///
    public void newInstanceId() { _instanceId = randomUUID(); }
    ///
    public @property bool hideInHirarchie() const { return _hideFlags.isSet(HideFlags.hideInHirarchie); }

    version(UEIncludeEditor)abstract @property string typename();

    ///
    void serialize(ref UESerializer serializer) 
    {
        alias T = typeof(this);
        alias v = this;

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
                
                enum hasSerializeUDA = hasUDA!(mixin("T."~m), Serialize);
                
                //pragma(msg, .format("> '%s' (%s)", m, hasSerializeUDA));
                
                static if(hasSerializeUDA)
                {
                    alias M = typeof(__traits(getMember, v, m));

                    enum memberOffset = __traits(getMember, v, m).offsetof;

                    serializer.serializeObjectMember!(T,M)(this, m, __traits(getMember, v, m));
                }
            }
        }
    }

    ///
    void deserialize(ref UEDeserializer serializer, string uid=null) 
    {
        import unecht.meta.uda;
        
        alias T = typeof(this);
        alias v = this;
        
        foreach(m; __traits(derivedMembers, T))
        {
            enum isMemberVariable = is(typeof(() {
                        __traits(getMember, v, m) = __traits(getMember, v, m).init;
                    }));
            
            enum isMethod = is(typeof(() {
                        __traits(getMember, v, m)();
                    }));
            
            enum isNonStatic = !is(typeof(mixin("&T."~m)));
            
            static if(isMemberVariable && isNonStatic && !isMethod) {
                
                enum hasSerializeUDA = hasUDA!(mixin("T."~m), Serialize);
                
                static if(hasSerializeUDA)
                {
                    alias M = typeof(__traits(getMember, v, m));
                    
                    serializer.deserializeObjectMember!(T,M)(this, uid, m, __traits(getMember, v, m));
                }
            }
        }
    }
    
    ///TBD
    static UEObject instantiate(UEObject obj)
    {
        //TODO:
        return null;
    }
}
