module unecht.core.defaultInspector;

version(UEIncludeEditor)
{
    import unecht.core.componentManager;
    import unecht.meta.uda;

    alias aliasHelper(alias T) = T;
    alias aliasHelper(T) = T;

    /// UDA
    struct UEInspectorTooltip
    {
        string txt;
    }

    ///
    struct UEDefaultInspector(T)
    {
        @EditorInspector(T.stringof)
        static class UEDefaultInspector(T) : IComponentEditor
        {
            import unecht.core.object;
            override void render(UEObject _component)
            {
                auto thisT = cast(T)_component;
                
                import derelict.imgui.imgui;
                import unecht.core.components.internal.gui;
                import std.string:format;

                /+ TODO: use orange way of finding members, this also implys to go up the class hirarchie at compile time

                pragma(msg, "-------------------");
                pragma(msg, T.stringof);
                pragma(msg, typeof(T.tupleof));

                import std.stdio;
                foreach(i, dummy; typeof(T.tupleof))
                {
                    alias typeof(T.tupleof[i]) Type;

                    //writefln("-%s",Type.stringof);

                    enum nameOfFieldAt = __traits(identifier, T.tupleof[i]);

                    pragma(msg, nameOfFieldAt);
                }
                +/
                
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
        
        mixin UERegisterInspector!(UEDefaultInspector!T);
    }
}
else
{
    struct UEDefaultInspector(T){}
}