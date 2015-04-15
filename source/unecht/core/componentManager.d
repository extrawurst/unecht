module unecht.core.componentManager;

version(UEIncludeEditor):

import unecht.core.component:UEComponent;

public import unecht.meta.uda;

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

struct UEInspectorTooltip
{
    string txt;
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

alias aliasHelper(alias T) = T;
alias aliasHelper(T) = T;

///
struct UEDefaultInspector(T)
{
    @EditorInspector(T.stringof)
    static class UEDefaultInspector(T) : IComponentEditor
    {
        override void render(UEComponent _component)
        {
            auto thisT = cast(T)_component;
            
            import derelict.imgui.imgui;
            import unecht.core.components.internal.gui;
            import std.string:format;

            foreach(memberName; __traits(allMembers, T))
            {
                //pragma(msg, memberName);

                static if(__traits(compiles, mixin("T."~memberName)))
                {
                    //pragma(msg, " ->access allowed");

                    alias member = aliasHelper!(__traits(getMember, T, memberName));

                    static if(is(typeof(member) : bool))
                    {
                        //pragma(msg, " -->bool");

                        UEGui.checkbox(member.stringof, mixin("thisT."~memberName));

                        static if(hasUDA!(mixin("T."~memberName),UEInspectorTooltip))
                        {
                            enum txt = getUDATemplate!(member,UEInspectorTooltip).txt;
                            if (ig_IsItemHovered())
                                ig_SetTooltip(txt);
                        }
                    }
                }
            }
        }
    }

    mixin UERegisterInspector!(UEDefaultInspector!T);
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