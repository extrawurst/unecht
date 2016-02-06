module unecht.core.object;

import std.uuid;

public import unecht.core.hideFlags;
import unecht.core.serialization.serializer;
import unecht.core.serialization.mixins;
import unecht.meta.uda;

///
static struct UECustomSerializeUUID
{
    import lang.sdl;

    private static void serialize(ref UUID v, ref UESerializer serializer, Tag parent)
    {
        serializer.serializeMember(v.toString(), parent);
    }

    private static void deserialize(ref UUID v, ref UEDeserializer serializer, Tag parent)
    {
        string uuidStr;
        serializer.deserializeMember(uuidStr, parent);
        v = UUID(uuidStr);
    }
}

/// base class for all serializable objects
abstract class UEObject
{
    ///
    this()
    {
        //TODO: find out why this is called at compile time (#87)
        if(!__ctfe)
        {
            newInstanceId();
        }
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

    version(UEIncludeEditor)public abstract @property string typename();

    ///
    public void serialize(ref UESerializer serializer) 
    {
        if(hideFlags.isSet(HideFlags.dontSaveInScene))
            return;
        
        iterateAllSerializables!(UEObject)(this, serializer);
    }

    ///
    public void deserialize(ref UEDeserializer serializer, string uid=null) 
    {
        if(uid != null)
            _instanceId = UUID(uid);

        iterateAllSerializables!(UEObject)(this, serializer);
    }
    
    ///TBD
    static UEObject instantiate(UEObject obj)
    {
        //TODO:
        return null;
    }

private:
    mixin generateObjectSerializeFunc!(serializeMember, UESerializer, "serialize");
    mixin generateObjectSerializeFunc!(deserializeMember, UEDeserializer, "deserialize");
    
    void serializeMember(T,M)(string m,ref M member, ref UESerializer serializer, UECustomFuncSerialize!M customFunc=null)
    {
        serializer.serializeObjectMember!(T,M)(this, m, member, customFunc);
    }

    void deserializeMember(T,M)(string m, ref M member, ref UEDeserializer serializer, UECustomFuncDeserialize!M customFunc=null)
    {
        string uid = null;

        if(_instanceId != UUID.init)
            uid = _instanceId.toString();

        serializer.deserializeObjectMember!(T,M)(this, uid, m, member, customFunc);
    }


    @Serialize
    {
        @CustomSerializer("UECustomSerializeUUID")
        UUID _instanceId;
        HideFlagSet _hideFlags;
    }
}
