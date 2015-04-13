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
            
            import derelict.imgui.imgui;
            import unecht.core.components.internal.gui;
            import std.format;

            UEGui.InputVec("pos",thisT._position);

            auto angles = thisT.angles;
            if(UEGui.InputVec("angles", angles))
                thisT.angles = angles;

            UEGui.InputVec("scale",thisT._scaling);

            UEGui.Text(format("to: %s",thisT.forward));
            UEGui.Text(format("up: %s",thisT.up));
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
    @property void scaling(vec3 v) { _scaling = v; }
    ///
    @property vec3 scaling() const { return _scaling; }
    ///
    @property void rotation(quat v) { setRotation(v); }
    ///
    @property quat rotation() const { return _rotation; }
    ///
    @property void angles(vec3 v) { setAngles(v); }
    ///
    @property vec3 angles() const { return _angles; }
    ///
    @property vec3 forward() const { return _dir; }
    ///
    @property vec3 right() const { return _right; }
    ///
    @property vec3 up() const { return _up; }
    
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

    ///
    private void setAngles(in vec3 v)
    {
        _angles = v;
        
        auto anglesInRad = v * (PI/180.0f);
        
        _rotation = quat.euler_rotation(anglesInRad.x,anglesInRad.y,anglesInRad.z);

        updateDirections(anglesInRad);
    }
    
    ///
    private void setRotation(in quat v)
    {
        _rotation = v;

        _angles.z = v.yaw;
        _angles.y = v.pitch;
        _angles.x = v.roll;
        
        const anglesInRad = _angles;

        //_rotation = quat.euler_rotation(v.pitch,v.yaw,v.roll);

        import gl3n.math:_180_PI;
        _angles *= _180_PI;

        updateDirections(anglesInRad);
    }
    
    ///
    private void updateDirections(in ref vec3 anglesInRad)
    {
        _dir = ORIG_DIR * _rotation;
        //_dir = _dir * quat.xrotation(anglesInRad.x);
        //_dir = _dir * quat.yrotation(anglesInRad.y);
        
        _up = ORIG_UP * _rotation;
        //_up = _up * quat.zrotation(anglesInRad.z);
        //_up = _up * quat.xrotation(anglesInRad.x);
        //_up = _up * quat.yrotation(anglesInRad.y);
        
        _right = cross(_dir,_up);
    }
    
private:
    UESceneNode _parent;
    vec3 _position = vec3(0);
    vec3 _scaling = vec3(1);
    quat _rotation = quat.identity;
    vec3 _dir = ORIG_DIR;
    vec3 _up = ORIG_UP;
    vec3 _right = cross(ORIG_DIR,ORIG_UP);
    vec3 _angles = vec3(0);

    static immutable vec3 ORIG_DIR = vec3(0,0,1);
    static immutable vec3 ORIG_UP = vec3(0,1,0);
}
