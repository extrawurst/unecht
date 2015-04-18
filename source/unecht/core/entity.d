module unecht.core.entity;

import derelict.util.system;

import unecht;
import unecht.core.components.sceneNode;

///
enum UELayer : uint
{
    all=0,
    editor,
}

static immutable uint UECameraDefaultLayers = 0xffffffff ^ (1<<UELayer.editor);

import unecht.core.stdex;
static assert(false == testBit(UECameraDefaultLayers,UELayer.editor));
static assert(true == testBit(UECameraDefaultLayers,UELayer.all));

/// 
final class UEEntity
{
    ///
	bool hideInEditor;

    @nogc @property{
    	///
        UESceneNode sceneNode() nothrow { return _sceneNode; } 
        ///
        bool destroyed() nothrow { return _destroyed; } 
    	///
        string name() const { return _name; } 
        ///
        void name(string v) { _name = v; } 
        ///
        UELayer layer() const { return _layer; }
        ///
        void layer(UELayer layer) { _layer = layer; }
    	///
        UEComponent[] components() { return _components; } 
    }

    ///
    void broadcast(string _method,ARG)(ARG _arg)
    {
        import std.string:format;
        foreach(component; _components)
        {
            enum mix = .format("component.%s(_arg);",_method);
            //pragma(msg, mix);
            mixin(mix);
        }
    }

    ///
    void broadcast(string _method)()
    {
        import std.string:format;
        foreach(component; _components)
        {
            enum mix = .format("component.%s();",_method);
            //pragma(msg, mix);
            mixin(mix);
        }
    }

    //TODO: optimize ?
    /// find first component of type T
    @nogc auto getComponent(T : UEComponent)() nothrow
    {
        foreach(c; _components)
        {
            auto c2t = cast(T)c;
            if(c2t)
                return c2t;
        }

        return null;
    }

	///
	auto addComponent(T : UEComponent)()
	{
		auto newT = new T();
		auto newcomp = cast(UEComponent)newT;

		addComponent(newcomp);

		return newT;
	}

	///
	UEComponent addComponent(string _type)
	{
		auto newcomp = cast(UEComponent)Object.factory(_type);
		assert(newcomp);

		addComponent(newcomp);

		return newcomp;
	}

	void removeComponent(UEComponent c)
	{
		import std.algorithm:countUntil,remove;
		auto idx = _components.countUntil(c);
		if(idx > -1)
		{
			c.onDestroy();
            ue.application.events.removeComponent(c);
			.destroy(c);

			_components = _components.remove(idx);
		}
	}

	/// factory method
	static auto create(string _name = null, UESceneNode _parent = null)
	{
        return new UEEntity(_parent ? _parent : ue.scene.root, _name);
	}

    ///
    static void destroy(UEEntity entity)
    {
        entity._destroyed = true;
    }

    ///
    static void destroyImmediate(UEEntity entity)
    {
        entity.doDestroy();
    }

private:

	this(UESceneNode _parent, string _name)
	{
		if(_name)
			this._name = _name;

		this._sceneNode = new UESceneNode();
		this._sceneNode.parent = _parent;

		addComponent(this._sceneNode);
	}

	void addComponent(UEComponent _comp)
	{
		_comp.setEntity(this);

		_components ~= _comp;

		_comp.onCreate();
	}

    void doDestroy()
    {
        foreach(child; this._sceneNode.children)
            child.entity.doDestroy();

        //unparenting of local components
        broadcast!("onDestroy")();

        _destroyed = true;
        _sceneNode = null;
        _name = null;

        foreach(component; _components)
        {
            component.setEntity(null);
            ue.events.removeComponent(component);
            .destroy(component);
        }
        _components.length = 0;
    }
	
private:
	string _name = "entity";

    bool _destroyed = false;

    UELayer _layer = UELayer.all;

	UESceneNode _sceneNode;
	
	UEComponent[] _components;
}