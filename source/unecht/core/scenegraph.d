module unecht.core.scenegraph;

import gl3n.linalg;

///
struct Transform
{
	mat4 matrixWorld = mat4.identity;
	mat4 matrixLocal = mat4.identity;
	bool invalidated = true;

	Transform*[] children;

	private Transform* parent;
}

///
final class Scenegraph
{
	Transform[] transforms;

	this()
	{
		transforms.length = 1;
	}

	void insert(Transform* _parent, ref Transform _node)
	{
		assert(_node.children.length == 0);

		transforms.length = transforms.length+1;

		auto idxPos = findTransform(_parent);

		auto ixLast = idxPos+1+countChildren(_parent);

		if(_parent.children.length > 0)
		{
			if(ixLast < transforms.length)
			{
				transforms[ixLast+1..$] = transforms[ixLast..$];
			}
		}

		transforms[ixLast+1] = _node;

		updateNode(&transforms[ixLast+1]);
	}

	void update()
	{
		foreach(ref t; transforms)
		{
			if(t.invalidated)
			{
				updateNode(&t);
			}
		}
	}

private:

	size_t countChildren(Transform* _t)
	{
		size_t res = _t.children.length;

		foreach(t; _t.children)
			res+=countChildren(_t);

		return res;
	}

	size_t findTransform(Transform* _t)
	{
		foreach(i; 0..transforms.length)
			if(&transforms[i] is _t)
				return i;

		throw new Exception("transform not found in graph");
	}

	void updateNode(Transform* _t)
	{
		_t.invalidated = false;

		if(_t.parent)
			_t.matrixWorld = _t.parent.matrixWorld * _t.matrixLocal;

		foreach(ref c; _t.children)
		{
			updateNode(c);
		}
	}
}

unittest
{
	Scenegraph sg = new Scenegraph();

	Transform t;

	assert(sg.transforms.length == 1);

	sg.insert(&sg.transforms[0], t);

	//assert(sg.transforms.length == 2);

	//sg.insert(&sg.transforms[0], t);

	//assert(sg.transforms.length == 3);
}