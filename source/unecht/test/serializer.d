module unecht.test.serializer;

version(unittest):

import unecht;
import unecht.core.serialization.serializer;
import unecht.core.hideFlags;
import sdlang;

struct CustomTestSerializer
{
    static void serialize(ref CustomSerializeTestStruct v, ref UESerializer serializer, Tag parent)
    {
        serializer.serializeMember(v.foobar, parent);
    }
    
    static void deserialize(ref CustomSerializeTestStruct v, ref UEDeserializer serializer, Tag parent)
    {
        serializer.deserializeMember(v.foobar, parent);
    }
}

struct CustomSerializeTestStruct
{
    int ignoreTest = 1;
    private int foobar = 2;
}

class Comp1: UEComponent
{
    mixin(UERegisterObject!());
    
    @Serialize
    int val;
}

class BaseComp: UEComponent
{
    mixin(UERegisterObject!());
    
    @Serialize
    int baseClassMember;
}

class Comp2: BaseComp
{
    mixin(UERegisterObject!());
    
    @Serialize{
        int i;
        bool b;
        float inf = 1;
        UEComponent comp1;
        Comp1 compHide;
        Comp1 comp1_;
        Comp1 compCheckNull;
        int[] intArr = [0,1];
        UEComponent[] compArr;
        int[2] intStatArr = [0,0];
        ubyte ub;
        ubyte[2] ubArr;
        @CustomSerializer("CustomTestSerializer")
        CustomSerializeTestStruct customSer;
        
        enum LocalEnum{foo,bar}
        vec2 v;
        quat q;
        
        alias AliasInt = int;
        
        LocalEnum e=LocalEnum.bar;
        AliasInt ai=2;
        
        private int priv;
    }
    
    int dont;
}

unittest
{
    import unecht.core.components.sceneNode:UESceneNode;
    import std.file:write;
    import std.conv:to;
    import std.format:format;
    import std.math:isNaN,isInfinity;
    
    UESceneNode n = new UESceneNode;
    n.hideFlags.set(HideFlags.dontSaveInScene);
    UEEntity e = UEEntity.create("test",n);
    e.sceneNode.angles = vec3(90,0,0);
    Comp1 comp1 = new Comp1();
    comp1.val = 50;
    Comp2 c = e.addComponent!Comp2;
    c.hideFlags = c.hideFlags.set(HideFlags.hideInInspector);
    c.compArr = [comp1,comp1,c];
    c.comp1 = comp1;
    c.compHide = e.addComponent!Comp1;
    c.compHide.val = 42;
    c.compHide.hideFlags.set(HideFlags.dontSaveInScene);
    c.v = vec2(10,20);
    c.ub = 2;
    c.q.y = 0.5f;
    c.inf = float.infinity;
    c.i=2;
    c.ai=3;
    c.b = true;
    c.intArr = [1,2];
    c.ubArr[0] = 128;
    c.intStatArr = [3,4];
    c.baseClassMember = 42;
    c.dont = 1;
    c.e=Comp2.LocalEnum.foo;
    c.comp1_ = comp1;
    c.customSer.ignoreTest = -1;
    c.customSer.foobar = -1;
    
    UESerializer s;
    c.serialize(s);
    
    auto serializeString = s.toString();

    write("serializationTest.txt", serializeString);
    
    UEDeserializer d = UEDeserializer(serializeString);
    Comp2 c2 = d.deserializeFirst!Comp2;
    
    assert(d.hasObjectId(to!string(e.instanceId)));
    assert(c2.i == c.i, format("%s != %s",c2.i,c.i));
    assert(c2.hideFlags == c.hideFlags,format("%s != %s",c2.hideFlags,c.hideFlags));
    assert(c2.instanceId == c.instanceId);
    assert(c2.ub == c.ub);
    assert(c2.ubArr[0] == c.ubArr[0]);
    assert(c2.sceneNode.angles.x == c.sceneNode.angles.x, format("%s != %s",c2.sceneNode.angles.x,c.sceneNode.angles.x));
    assert(c2.v == c.v, format("%s",c2.v));
    assert(c2.q.x.isNaN);
    assert(c2.q.y == c.q.y, format("%s",c2.q));
    assert(c2.inf.isInfinity, format("%s != float.isInfinity",c2.inf));
    assert(c2.b == c.b);
    assert(c2.intArr == c.intArr);
    assert(c2.intStatArr == c.intStatArr);
    assert(c2.ai == c.ai);
    assert(c2.e == c.e);
    assert(c2.baseClassMember == c.baseClassMember, format("%s != %s",c2.baseClassMember,c.baseClassMember));
    assert(c2.dont != c.dont);
    assert(c2.customSer.ignoreTest == CustomSerializeTestStruct.init.ignoreTest);
    assert(c2.customSer.foobar == c.customSer.foobar);
    assert(c2.entity !is null);
    assert(c2.entity.name == "test");
    assert(c2.compArr.length == 3);
    assert(c2.compArr[0] == c2.compArr[1]);
    assert(c2.compArr[2] is c2, format("%s != %s",c2.compArr[2].instanceId,c2.instanceId));
    assert((cast(Comp1)c2.comp1).val == (cast(Comp1)c.comp1).val);
    assert(c2.comp1 is c2.comp1_);
    assert(c2.entity.instanceId == c.entity.instanceId, format("%s != %s", c2.entity.instanceId,c.entity.instanceId));
}