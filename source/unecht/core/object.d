module unecht.core.object;

import unecht.core.componentSerialization;

///
abstract class UEObject
{
    import unecht.core.hideFlags;
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
    @Serialize
    {
        public UUID instanceId;
        public HideFlagSet hideFlags;
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