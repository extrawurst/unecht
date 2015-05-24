module unecht.core.object;

public import unecht.core.hideFlags;
import unecht.core.serialization.serializer;
import unecht.meta.uda;

///
static struct UECustomSerializeUUID
{
    import sdlang;
    import std.uuid;

    static void serialize(ref UUID v, ref UESerializer serializer, Tag parent)
    {
        serializer.serializeMember(v.toString(), parent);
    }
    
    static void deserialize(ref UUID v, ref UEDeserializer serializer, Tag parent)
    {
        string uuidStr;
        serializer.deserializeMember(uuidStr, parent);
        v = UUID(uuidStr);
    }
}

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
        @CustomSerializer("UECustomSerializeUUID")
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

                    enum hasCustomSerializerUDA = hasUDA!(__traits(getMember, T, m), CustomSerializer);
                    
                    static if(!hasCustomSerializerUDA)
                    {
                        serializer.serializeObjectMember!(T,M)(this, m, __traits(getMember, v, m));
                    }
                    else
                    {
                        enum customSerializerUDA = getUDA!(__traits(getMember, T, m), CustomSerializer);
                        
                        enum n = customSerializerUDA.serializerTypeName;

                        import sdlang;

                        UECustomFuncSerialize!M func = mixin("&"~n~".serialize");
                        
                        serializer.serializeObjectMember!(T,M)(this, m, __traits(getMember, v, m), func);
                    }
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
                    
                    enum hasCustomSerializerUDA = hasUDA!(__traits(getMember, T, m), CustomSerializer);
                    
                    static if(!hasCustomSerializerUDA)
                    {
                        serializer.deserializeObjectMember!(T,M)(this, uid, m, __traits(getMember, v, m));
                    }
                    else
                    {
                        enum customSerializerUDA = getUDA!(__traits(getMember, T, m), CustomSerializer);
                        
                        enum n = customSerializerUDA.serializerTypeName;

                        import sdlang;
                        
                        UECustomFuncDeserialize!M func = mixin("&"~n~".deserialize");
                        
                        serializer.deserializeObjectMember!(T,M)(this, uid, m, __traits(getMember, v, m), func);
                    }
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
