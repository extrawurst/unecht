module unecht.core.scenegraph;

import gl3n.linalg;

///
final class UESceneNode
{
public:
	mat4 matrixWorld = mat4.identity;
	mat4 matrixLocal = mat4.identity;
	bool invalidated = true;

	UESceneNode[] children;

	///
	@property const(UESceneNode) parent() const { return _parent; }
	///
	@property void parent(UESceneNode _parent) { setParent(_parent); }

private:

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

	void detachChild(UESceneNode _node)
	{
		import unecht.core.stdex;
		children = children.removeElement(_node);
	}

	void attachChild(UESceneNode _node)
	{
		children ~= _node;
	}

private:
	UESceneNode _parent;
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