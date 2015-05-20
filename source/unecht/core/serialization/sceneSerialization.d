module unecht.core.serialization.sceneSerialization;

import unecht.core.components.sceneNode;
import unecht.core.componentSerialization;

import sdlang;

///
struct UESceneSerializer
{
    UESerializer baseSerializer;
    
    alias baseSerializer this;
    
    private Tag sceneNodesTag;
    
    void serialize(UESceneNode node)
    {
        if(!sceneNodesTag)
        {
            sceneNodesTag = new Tag();
            sceneNodesTag.name = "nodes";
        }
        
        node.serialize(baseSerializer);
        
        auto nodeTag = new Tag(sceneNodesTag);
        nodeTag.add(Value(node.instanceId.toString()));
    }
    
    public string toString()
    {
        auto root = new Tag;
        
        root.add(sceneNodesTag);
        root.add(baseSerializer.content);
        
        return root.toSDLDocument();
    }
}

///
struct UESceneDeserializer
{
    UEDeserializer base;
    
    alias base this;
    
    private Tag sceneNodesTag;
    
    this(string input)
    {
        base = UEDeserializer(input);

        sceneNodesTag = root.all.tags["nodes"][0];
        assert(sceneNodesTag !is null);
    }
    
    void deserialize(UESceneNode root)
    {
        foreach(Tag node; sceneNodesTag.all.tags)
        {
            auto id = node.values[0].get!string;

            auto scenenode = new UESceneNode;
            scenenode.parent = root;
            scenenode.deserialize(this,id);
        }
    }
}