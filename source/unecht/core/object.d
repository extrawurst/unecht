module unecht.core.object;

import unecht.core.componentSerialization;

///
abstract class UEObject
{
    import unecht.core.hideFlags;
    
    private static int instanceIdPool = 0;
    
    ///
    this()
    {
        if(!__ctfe)
            instanceId = instanceIdPool++;
    }
    
    //TODO: see #79
    @Serialize
    {
        public int instanceId;
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