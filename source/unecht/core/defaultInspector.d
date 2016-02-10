module unecht.core.defaultInspector;

/// UDA
struct UEInspectorTooltip
{
    string txt;
}

version(UEIncludeEditor)
{
    alias aliasHelper(alias T) = T;
    alias aliasHelper(T) = T;

    import unecht.meta.uda;
    import unecht.core.object;
    import unecht.core.components.internal.gui;
    import unecht.core.componentManager:IComponentEditor;

    import derelict.imgui.imgui;
        
    static class UEDefaultInspector(T) : IComponentEditor
    {
        /+private static void renderOject(UEObject _component)
        {
            UEGui.Text("default for: " ~ T.stringof);
        }+/

        override void render(UEObject _component)
        {
            //renderOject(_component);

            auto thisT = cast(T)_component;
            
            import derelict.imgui.imgui;
            import unecht.core.components.internal.gui;
            import std.string:format;

            //pragma(msg, "-------------------");
            //pragma(msg, T.stringof);
            //pragma(msg, typeof(T.tupleof));
            
            foreach(memberName; __traits(allMembers, T))
            {
                //pragma(msg, ">"~memberName);
                
                static if(__traits(compiles, mixin("T."~memberName)))
                {
                    enum isMemberVariable = is(typeof(() {
                                __traits(getMember, thisT, memberName) = __traits(getMember, thisT, memberName).init;
                            }));
                    
                    enum isMethod = is(typeof(() {
                                __traits(getMember, thisT, memberName)();
                            }));
                    
                    enum isNonStatic = !is(typeof(mixin("&T."~memberName)));

                    static if(isNonStatic && !isMethod && isMemberVariable)
                    {
                        alias member = aliasHelper!(__traits(getMember, T, memberName));
                        
                        static if(is(typeof(member) : bool))
                        {
                            //pragma(msg, " -->bool");
                            
                            UEGui.checkbox(member.stringof, mixin("thisT."~memberName));
                            
                            static if(hasUDA!(mixin("T."~memberName),UEInspectorTooltip))
                            {
                                enum txt = getUDA!(member,UEInspectorTooltip).txt;
                                if (igIsItemHovered())
                                    igSetTooltip(txt);
                            }
                        }
                        else static if(is(typeof(member) : int) && !is(typeof(member) == enum))
                        {
                            //pragma(msg, " -->int");
                            
                            UEGui.DragInt(member.stringof, mixin("thisT."~memberName));
                            
                            static if(hasUDA!(mixin("T."~memberName),UEInspectorTooltip))
                            {
                                enum txt = getUDA!(member,UEInspectorTooltip).txt;
                                if (igIsItemHovered())
                                    igSetTooltip(txt);
                            }
                        }
                        else static if(is(typeof(member) == enum))
                        {
                            //pragma(msg, " -->enum");

                            UEGui.EnumCombo(memberName, __traits(getMember, thisT, memberName));
                        }
                        else static if(is(typeof(member) : float))
                        {
                            //pragma(msg, " -->float");
                            
                            UEGui.DragFloat(member.stringof, mixin("thisT."~memberName));
                            
                            static if(hasUDA!(mixin("T."~memberName),UEInspectorTooltip))
                            {
                                enum txt = getUDA!(member,UEInspectorTooltip).txt;
                                if (igIsItemHovered())
                                    igSetTooltip(txt);
                            }
                        }
                    }
                }
            }
        }
    }
}
else
{
    struct UEDefaultInspector(T){}
}