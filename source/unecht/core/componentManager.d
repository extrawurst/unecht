module unecht.core.componentManager;

version(UEIncludeEditor):

import unecht.core.component:UEComponent;

public import unecht.meta.uda:getUDA;

import std.format;

///
template UERegisterInspector(T)
{
    enum UERegisterInspector = .format(q{
        shared static this()
        {
            enum componentName = getUDA!(%s,EditorInspector)().componentName;
            UEComponentsManager.editors[componentName] = new %s();
        }
        },T.stringof,T.stringof);
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

/+ find all modules 
foreach(member; __traits(allMembers, someModule)) 
    static if(is(__traits(getMember, someModule, member))) { /* member is a type declaration */ } 
    else static if(member.startsWith("import ")) { /* member is an import declaration */ } 
 +/

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