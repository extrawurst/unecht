module unecht.core.components.sceneNode;

import gl3n.linalg;

import unecht.core.component;
import unecht.core.componentManager;

//TODO: create mixin
version(UEIncludeEditor)
{
    @EditorInspector("UESceneNode")
    static class UESceneNodeInspector : IComponentEditor
    {
        override void render(UEComponent _component)
        {
            auto thisT = cast(UESceneNode)_component;
            
            import imgui;
            import std.format;
            
            imguiLabel(format("pos: %s",thisT.position));
            imguiLabel(format("rot: %s",thisT.rotation));
            imguiLabel(format("scale: %s",thisT.scaling));
        }
        
        mixin UERegisterInspector!UESceneNodeInspector;
    }
}

///
final class UESceneNode : UEComponent
{
    mixin(UERegisterComponent!());
    
public:

    ///
    UESceneNode[] children;
    
    ///
    @property const(UESceneNode) parent() const { return _parent; }
    ///
    @property void parent(UESceneNode _parent) { setParent(_parent); }
    ///
    @property void position(vec3 _v) { _position = _v; }
    ///
    @property vec3 position() const { return _position; }
    ///
    @property void scaling(vec3 _v) { _scaling = _v; }
    ///
    @property vec3 scaling() const { return _scaling; }
    ///
    @property void rotation(quat _v) { _rotation = _v; }
    ///
    @property quat rotation() const { return _rotation; }
    
private:
    
    ///
    void setParent(UESceneNode _node)
    {
        assert(_node, "null parent not allowed");
        
        if(this._parent)
        {
            this._parent.detachChild(this);
        }
        
        this._parent = _node;
        
        this._parent.attachChild(this);
    }
    
    ///
    void detachChild(UESceneNode _node)
    {
        import unecht.core.stdex;
        children = children.removeElement(_node);
    }
    
    ///
    void attachChild(UESceneNode _node)
    {
        children ~= _node;
    }
    
private:
    UESceneNode _parent;
    vec3 _position = vec3(0);
    vec3 _scaling = vec3(1);
    quat _rotation = quat.identity;
}
