module unecht.core.scenegraph;

import gl3n.linalg;

import unecht;
import unecht.core.componentManager;

//TODO: create mixin
version(UEIncludeEditor)
{
static class UESceneNodeInspector : IComponentEditor
{
	override void render(UEComponent _component)
	{
		auto thisT = cast(UESceneNode)_component;
		
		import imgui;
		import std.format;

		imguiLabel(format("pos: %s",thisT.position));
	}

	shared static this()
	{
		UEComponentsManager.editors["UESceneNode"] = new UESceneNodeInspector();
	}
}
}

///
final class UESceneNode : UEComponent
{
	mixin(UERegisterComponent!());

public:
	mat4 matrixWorld = mat4.identity;
	mat4 matrixLocal = mat4.identity;
	bool invalidated = true;

	UESceneNode[] children;

	///
	@property const(UESceneNode) parent() const { return _parent; }
	///
	@property void parent(UESceneNode _parent) { setParent(_parent); }
	///
	@property void position(vec3 _pos) { _position = _pos; }
	///
	@property vec3 position() const { return _position; }

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
}

///
final class UEScenegraph
{
public:

	///
	@property UESceneNode root() {return _root;}

	///
	void update()
	{
		updateNode(_root);

		//TODO: optimize this
		auto allComponents = gatherAllComponents!UEComponent();
		foreach(c; allComponents)
			c.onUpdate();
	}

	///
	auto gatherAllComponents(T : UEComponent)()
	{
		T[] res;
		gatherAllComponentsInNode!T(_root,res);
		return res;
	}

	private void gatherAllComponentsInNode(T : UEComponent)(UESceneNode _node, ref T[] _result)
	{
		if(_node.entity)
		{
			foreach(c; _node.entity.components)
			{
				auto componentAsT = cast(T)c;
				if(componentAsT)
					_result ~= componentAsT;
			}
		}

		foreach(child; _node.children)
			gatherAllComponentsInNode!T(child,_result);
	}

	private void updateNode(UESceneNode _node)
	{
		if(!_node)
			return;

		if(_node.parent && _node.invalidated)
		{
			//TODO: update matrix

			_node.invalidated = false;
		}

		foreach(node; _node.children)
			updateNode(node);
	}

private:
	UESceneNode _root = new UESceneNode();
}

unittest
{
	//TODO:
	import std.stdio;
	writefln("TODO: write tests for scenegraph");
}