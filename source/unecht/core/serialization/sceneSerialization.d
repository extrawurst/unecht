module unecht.core.serialization.sceneSerialization;

import std.uuid;

import unecht.core.components.sceneNode;
import unecht.core.serialization.serializer;

import sdlang;

///
struct UESceneSerializer
{
    private UESerializer baseSerializer;

    ///
    alias baseSerializer this;
    
    private Tag sceneNodesTag;

    ///
    public void serialize(UESceneNode root, UUID[] externals=null)
    {
        if(!sceneNodesTag)
        {
            sceneNodesTag = new Tag();
            sceneNodesTag.name = "nodes";
        }

        if(externals)
            baseSerializer.externals = externals;
        
        baseSerializer.blacklist ~= root.instanceId;

        foreach(rootChild; root.children)
        {
            serializeNode(rootChild);
        }
    }

    private void serializeNode(UESceneNode node)
    {
        import unecht.core.hideFlags;
        if(!node.hideFlags.isSet(HideFlags.hideInHirarchie))
        {
            node.serialize(baseSerializer);
            
            auto nodeTag = new Tag(sceneNodesTag);
            nodeTag.add(Value(node.instanceId.toString()));
        }
    }

    ///
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

    ///
    alias base this;
    
    private Tag sceneNodesTag;

    ///
    this(string input)
    {
        base = UEDeserializer(input);

        sceneNodesTag = root.all.tags["nodes"][0];
        assert(sceneNodesTag !is null);
    }

    ///
    public void deserialize(UESceneNode root)
    {
        assert(root);

        import unecht.core.logger;

        foreach(Tag node; sceneNodesTag.all.tags)
        {
            auto id = node.values[0].get!string;

            auto scenenode = cast(UESceneNode)base.findLoadedRef(id);

            if(scenenode is null)
            {
                scenenode = new UESceneNode;
                base.storeLoadedRef(scenenode,id);
                scenenode.deserialize(this,id);
                assert(scenenode.parent is null);
                scenenode.parent = root;

                /+log.logf("new node added: '%s' (%s,%s)", 
                    scenenode.entity.name, 
                    scenenode.parent.children.length, 
                    scenenode.children.length);
                log.logf("->: %s parent: %s", scenenode.instanceId, scenenode.parent.instanceId);+/
            }
            else
            {
                //log.logf("node already created: '%s' (%s)", scenenode.entity.name, scenenode.instanceId);

                assert(scenenode.parent is root || scenenode.parent is null);
                if(scenenode.parent is null)
                    scenenode.parent = root;
            }
        }

        void recursiveCreate(UESceneNode _node)
        {
            foreach(child; _node.children)
            {
                recursiveCreate(child);
            }

            foreach(comp; _node.entity.components)
            {
                comp.onCreate();
            }
        }
        
        foreach(Tag node; sceneNodesTag.all.tags)
        {
            auto id = node.values[0].get!string;

            auto scenenode = cast(UESceneNode)base.findLoadedRef(id);

            assert(scenenode);

            recursiveCreate(scenenode);
        }

        foreach(i,lo; base.objectsLoaded)
        {
            import unecht.core.object;
            import unecht.core.entity;
            UEObject o = lo.o;
            assert(o);

            //import std.stdio;
            //writefln("loaded [%s]: %s", i, o.instanceId);

            if(cast(UESceneNode)o)
            {
                UESceneNode n = cast(UESceneNode)o;
                assert(n.entity);
                //writefln(" sceneNode -> %s ('%s')", n.children.length, n.entity.name);
                //if(n.parent)
                //    writefln(" parent -> %s", n.parent.instanceId);
            }
            if(cast(UEEntity)o)
            {
                UEEntity e = cast(UEEntity)o;
                assert(e.sceneNode);
                //writefln(" entity '%s': %s", e.name, e.sceneNode.instanceId);
            }
        }
        
        void val(UESceneNode n,UESceneNode root)
        {
            assert(n);

            if(n !is root)
            {
                assert(n.parent, format("no parent: %s",n.instanceId));
                assert(n.parent.hasChild(n));
            }

            foreach(sn; n.children)
            {
                assert(sn.parent is n, format("'%s'.%s !is '%s'.%s", sn.entity.name, sn.parent.instanceId, n.entity.name,n.instanceId));
                val(sn,root);
            }
        }

        // validity check
        val(root,root);
    }
}