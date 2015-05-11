module unecht.core.scenegraph;

import gl3n.linalg;

import unecht.core.component;
import unecht.core.entity;
import unecht.core.components.sceneNode;

///
final class UEScenegraph
{
public:

	///
	@property UESceneNode root() {return _root;}
	///
	@property void playing(bool _v) { _playing=_v; }
	///
	@property bool playing() const { return _playing; }
	///
	@property void step() { _singleStep = true; }

	///
	void update()
	{
		updateNode(_root);

        foreach(toDestroy; _destroyedEntites)
            UEEntity.destroyImmediate(toDestroy);

        _destroyedEntites.length = 0;

		if(_playing || _singleStep)
		{
			_singleStep=false;

			//TODO: optimize this
			auto allComponents = gatherAllComponents!UEComponent();
			foreach(c; allComponents)
				c.onUpdate();
		}
        else
        {
            import unecht;
            UEEvent ev;
            ev.eventType = UEEventType.updateEditMode;
            ue.events.trigger(ev);
        }
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

        if(_node.entity && _node.entity.destroyed)
            _destroyedEntites ~= _node.entity;

		foreach(node; _node.children)
			updateNode(node);
	}

private:
	UESceneNode _root = new UESceneNode();
    UEEntity[] _destroyedEntites;
	bool _playing=true;
	bool _singleStep=false;
}

unittest
{
	//TODO:
	import std.stdio;
	writefln("TODO: write tests for scenegraph");
}