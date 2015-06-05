module unecht.core.componentManager;

version(UEIncludeEditor):

import unecht.core.object;
import unecht.core.components.editor.menus:EditorMenuItem;

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
	void render(UEObject _component);
}

///
static struct UEComponentsManager
{
	static IComponentEditor[string] editors;
    static string[] componentNames;
    version(UEIncludeEditor)static EditorMenuItem[] menuItems;
}

///
private bool hasBaseClass(in TypeInfo_Class v, in TypeInfo_Class base) pure nothrow
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
    import unecht.core.component;
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

                scope comp = cast(UEComponent)cla.create();
                if(comp)
                {
                    comp.getMenuItems(UEComponentsManager.menuItems);
                }
            }
        }       
    }
}