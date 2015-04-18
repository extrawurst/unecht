module unecht.core.componentManager;

version(UEIncludeEditor):

import unecht.core.component:UEComponent;

///
mixin template UERegisterInspector(T)
{
    shared static this()
    {
        import unecht.meta.uda:getUDA;
        enum componentName = getUDA!(T,EditorInspector).componentName;
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
    static string[] componentNames;
}

bool hasBaseClass(in TypeInfo_Class v, in TypeInfo_Class base)
{
    if(v is base)
        return true;
    else if(v && v !is typeid(Object))
        return hasBaseClass(v.base, base);
    else
        return false;
}

shared static this()
{
    auto tid = typeid(UEComponent);
   
    import std.stdio;
    foreach(m; ModuleInfo)
    {
        //writefln("scan mod: %s",m.name);

        foreach(cla; m.localClasses)
        {
            if(hasBaseClass(cla, tid))
            {
                //writefln("component: %s",cla.name);
                UEComponentsManager.componentNames ~= cla.name;
            }
        }       
    }
}