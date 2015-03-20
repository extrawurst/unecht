module unecht.core.entity;

import gl3n.linalg:vec3;

import unecht;
import unecht.core.scenegraph;

/// 
final class UEEntity
{
	bool hideInEditor;
	///
	@property UESceneNode sceneNode() { return _sceneNode; } 
	///
	@property string name() { return _name; } 

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

	/// factory method
	static auto create(string _name = null)
	{
		return new UEEntity(ue.scene.root, _name);
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
		
		_comp.onCreate();
		
		_components ~= _comp;
	}
	
private:
	string _name = "entity";

	UESceneNode _sceneNode;
	
	UEComponent[] _components;
}