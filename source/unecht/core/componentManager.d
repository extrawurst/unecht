module unecht.core.componentManager;

version(UEIncludeEditor):

import unecht.core.object;
import unecht.core.components.editor.menus:EditorMenuItem;

//TODO: get rid using new editor creation
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
    ///
    string componentName;
}

///
interface IComponentEditor
{	
    ///
	bool render(UEObject _component);
}

///
static struct UEComponentsManager
{
    ///
	static IComponentEditor[string] editors;
    ///
    static string[] componentNames;
    ///
    version(UEIncludeEditor)static EditorMenuItem[] menuItems;

    ///
    static void initComponentManager()
    {
        import unecht.core.component;
        import std.stdio;

        auto tid = typeid(UEObject);

        foreach(m; ModuleInfo)
        {
            //writefln("scan mod: %s",m.name);

            foreach(cla; m.localClasses)
            {
                if(hasBaseClass(cla, tid))
                {
                    //writefln("obj: %s",cla.name);

                    scope obj = cast(UEObject)cla.create();
                    if(obj)
                    {
                        auto editor = obj.createEditor();
                        if(editor)
                        {
                            // only add editor if not already registered by a custom implementation
                            if(!(obj.typename in UEComponentsManager.editors))
                                UEComponentsManager.editors[obj.typename] = editor;
                        }
                    }

                    if(hasBaseClass(cla, typeid(UEComponent)))
                    {
                        scope comp = cast(UEComponent)cla.create();
                        if(comp)
                        {
                            UEComponentsManager.componentNames ~= cla.name;
                            comp.getMenuItems(UEComponentsManager.menuItems);
                        }
                    }
                }
            }       
        }
    }
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