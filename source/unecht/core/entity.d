module unecht.core.entity;

import gl3n.linalg:vec3;

import unecht;
import unecht.core.scenegraph;

/// 
class UEEntity
{
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
	static auto create()
	{
		return new UEEntity(ue.scene.root);
	}

private:

	this(UESceneNode _parent)
	{
		this.sceneNode = new UESceneNode();
		this.sceneNode.parent = _parent;
	}

	void addComponent(UEComponent _comp)
	{
		_comp.setEntity(this);
		
		_comp.onCreate();
		
		components ~= _comp;
	}
	
private:
	string name = "entity";

	UESceneNode sceneNode;
	
	UEComponent[] components;
}