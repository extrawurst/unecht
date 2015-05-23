module unecht.test.sceneSerialization;

version(unittest):

import unecht;
import unecht.core.components.sceneNode;
import unecht.core.serialization.sceneSerialization;

unittest
{
    //import std.stdio;
    //writefln("------TEST 1----------------");

    UESceneNode root = new UESceneNode;
    auto entity1 = UEEntity.create("e1",root);
    auto entity2 = UEEntity.create("e2",entity1.sceneNode);
    auto entity3 = UEEntity.create("e3",entity2.sceneNode);
    auto entity4 = UEEntity.create("e4",root);
    assert(entity1.sceneNode is entity2.sceneNode.parent);
    assert(entity1.sceneNode.children.length == 1);

    UESerializer s;
    entity1.sceneNode.serialize(s);
    
    auto serializeString = s.toString();

    //writefln("%s",serializeString);
    //writefln("----------------------");

    UEDeserializer d = UEDeserializer(serializeString);
    UESceneNode result = d.deserializeFirst!UESceneNode();

    assert(result.entity.name == "e1");
    assert(result.entity.components.length == 1);   
    assert(result.entity.components[0] is result.entity.sceneNode);
    assert(result is result.entity.sceneNode, format("%s !is %s",result.instanceId,result.entity.sceneNode.instanceId));

    assert(result.instanceId == entity1.sceneNode.instanceId);
    assert(result.entity.instanceId == entity1.instanceId);

    assert(result.children.length == 1, format("%s",result.children.length));

    void val(UESceneNode n)
    {
        if(n.parent)
        {
            assert(n.parent.hasChild(n));
        }
        
        foreach(sn; n.children)
        {
            assert(sn.parent is n, format("'%s'.%s !is '%s'.%s", sn.entity.name, sn.parent.instanceId, n.entity.name,n.instanceId));
            val(sn);
        }
    }

    val(result);
}

class Test : UEComponent
{
    mixin(UERegisterObject!());

    UEEntity e;
}

unittest
{
    //import std.stdio;
    //writefln("------TEST 2----------------");

    UESceneNode root = new UESceneNode;
    auto entity0 = UEEntity.create("e0",root);
    auto t = entity0.addComponent!Test;
    auto entity3 = UEEntity.create("e3",root);
    auto entity1 = UEEntity.create("e1",root);
    t.e = entity1;
    auto entity2 = UEEntity.create("e2",entity1.sceneNode);
    auto entity4 = UEEntity.create("e4",root);
    import unecht.core.hideFlags;
    entity3.sceneNode.hideFlags.set(HideFlags.hideInHirarchie);

    UESceneSerializer s;
    s.serialize(root);

    //writefln("root: '%s'",root.instanceId);
    
    auto serializeString = s.toString();

    //writefln("%s",serializeString);
    //writefln("----------------------");

    UESceneDeserializer d = UESceneDeserializer(serializeString);
    UESceneNode result = new UESceneNode;
    d.deserialize(result);

    assert(result.children.length == 3);
    assert(result.children[0].entity.instanceId == entity0.instanceId);
    assert(result.children[1].entity.instanceId == entity1.instanceId);
    assert(result.children[1].children.length == 1);
    assert(result.children[1].children[0].entity.instanceId == entity2.instanceId);
    assert(result.children[2].entity.instanceId == entity4.instanceId);
}