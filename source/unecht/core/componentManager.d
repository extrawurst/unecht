module unecht.core.componentManager;

version(UEIncludeEditor):

import unecht.core.component:UEComponent;

import unecht.meta.uda:getUDA;

///
mixin template UERegisterInspector(T)
{
    shared static this()
    {
        enum componentName = getUDA!(T,EditorInspector)().componentName;
        UEComponentsManager.editors[componentName] = new T();
    }
}

/// UDA
struct EditorInspector
{
    string componentName;
}

///
interface IComponentEditor
{	
	void render(UEComponent _component);
}

///
static struct UEComponentsManager
{
	static IComponentEditor[string] editors;
}

/+shared static this()
{
    auto tid = typeid(IComponentEditor);

    //TODO: find and register all IComponentEditor's generically here
   
    import std.stdio;
    foreach(m; ModuleInfo)
    {
        writefln("scan mod: %s",m.name);

        foreach(cla; m.localClasses)
        {
            writefln("class: %s",cla.name);
            foreach(i; cla.interfaces)
            {
                if(i.classinfo is tid.info)
                {
                    writefln("found: %s",cla.name);
                    break;
                }
            }
        }       
    }
}+/