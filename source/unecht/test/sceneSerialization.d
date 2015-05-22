module unecht.test.sceneSerialization;

//version(unittest):

import unecht;
import unecht.core.components.sceneNode;

unittest
{
    UESceneNode root = new UESceneNode;
    auto entity1 = UEEntity.create("e1",root);
    auto entity2 = UEEntity.create("e2",entity1.sceneNode);
    assert(entity1.sceneNode is entity2.sceneNode.parent);
    assert(entity1.sceneNode.children.length == 1);

    UESerializer s;
    entity1.sceneNode.serialize(s);
    
    auto serializeString = s.toString();

    import std.stdio;
    writefln("%s",serializeString);
    
    //import std.file:write;
    //write("serializationTest2.txt", serializeString);

    UESceneNode dummy = new UESceneNode;
    UESceneNode result = new UESceneNode;
    UEDeserializer d = UEDeserializer(serializeString,dummy);
    result.deserialize(d);

    assert(result.entity.name == "e1");
    assert(result.entity.components.length == 1);
    assert(result.entity.components[0] is result.entity.sceneNode);
    assert(result is result.entity.sceneNode);

    assert(result.instanceId == entity1.sceneNode.instanceId);
    assert(result.entity.instanceId == entity1.instanceId);

    assert(result.children.length == 1, format("%s",result.children.length));
    //assert(result.entity.sceneNode is result.children[0].parent);
    //assert(dummy.children.length == 0, format("%s",dummy.children[0].entity.name));
}