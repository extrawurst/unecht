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
    private UESceneNode _sceneRoot;
    
    this(string input)
    {
        _sceneRoot = new UESceneNode;
        base = UEDeserializer(input, _sceneRoot);

        sceneNodesTag = root.all.tags["nodes"][0];
        assert(sceneNodesTag !is null);
    }
    
    void deserialize(UESceneNode root)
    {
        assert(root);

        foreach(Tag node; sceneNodesTag.all.tags)
        {
            auto id = node.values[0].get!string;

            auto scenenode = cast(UESceneNode)base.findObject(id);
            //TODO: can this happen ?
            assert(scenenode is null);

            if(scenenode is null)
            {
                scenenode = new UESceneNode;
                scenenode.deserialize(this,id);
                scenenode.parent = root;

                //import std.stdio;
                //writefln("new node added: %s (%s,%s)",scenenode.entity.name,scenenode.parent.children.length,scenenode.children.length);
                //writefln("->: %s parent: %s",scenenode.instanceId,scenenode.parent.instanceId);
            }
        }

        // validity check
        foreach(sn; _sceneRoot.children)
        {
            assert(sn.parent.hasChild(sn));
        }
    }
}