module unecht.core.scenegraph;

import std.uuid;

import gl3n.linalg;

import unecht.core.component;
import unecht.core.entity;
import unecht.core.components.sceneNode;
import unecht.core.object;

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
    this()
    {
        _root = new UESceneNode();
        import unecht.core.hideFlags;
        _root.hideFlags.set(HideFlags.dontSaveInScene);
    }

	///
	void update()
	{
		updateNode(_root);

        executeDestruction();

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

    ///
    public UEObject findObject(UUID id)
    {
        return findObjectRecursive(root, id);
    }

    ///
    private UEObject findObjectRecursive(UESceneNode node, UUID id)
    {
        if(node.instanceId == id)
            return node;

        if(node.entity)
        {
            foreach(c; node.entity.components)
            {
                if(c.instanceId == id)
                    return c;
            }
        }

        foreach(c; node.children)
        {
            if(c.instanceId == id)
                return c;
        }

        return null;
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

    private void executeDestruction()
    {
        if(_destroyedEntites.length > 0)
        {
            //dump();

            foreach(toDestroy; _destroyedEntites)
                UEEntity.destroyImmediate(toDestroy);
            
            _destroyedEntites.length = 0;

            //dump();
        }
    }

    public void dump()
    {
        import unecht.core.logger;
        log.infof("\ndump root: %s",_root.children.length);
        
        foreach(child; _root.children)
        {
            log.infof(" - %s (%s)", child.entity.name, child.sceneNode.entity.instanceId);
        }
    }

private:
    UESceneNode _root;
    UEEntity[] _destroyedEntites;
	bool _playing=true;
	bool _singleStep=false;
}

unittest
{
	//TODO:
    import unecht.core.logger;
	log.info("TODO: write tests for scenegraph");
}