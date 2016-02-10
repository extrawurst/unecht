module unecht.core.defaultInspector;

/// UDA
struct UEInspectorTooltip
{
    string txt;
}

version(UEIncludeEditor){

    alias aliasHelper(alias T) = T;
    alias aliasHelper(T) = T;

    import unecht.meta.uda;
    import unecht.core.object;
    import unecht.core.entity;
    import unecht.core.component;
    import unecht.core.components.internal.gui;
    import unecht.core.componentManager:IComponentEditor;

    import derelict.imgui.imgui;

    private static bool renderBaseClasses(T)(T _v)
    {
        import std.traits:BaseClassesTuple;

        static if(BaseClassesTuple!T.length > 1)
        {
            return renderMembers!(BaseClassesTuple!T[0])(_v);
        }
    }

    private static bool renderMembers(T)(T _v)
    {
        import std.traits:FieldNameTuple;

        bool changesInMembers;
        foreach(idx, name; FieldNameTuple!T) 
        {
            const(char)* tooltip;

            static if(hasUDA!(_v.tupleof[idx],UEInspectorTooltip))
            {
                tooltip = getUDA!(_v.tupleof[idx],UEInspectorTooltip).txt;
            }

            if(renderEditor!(typeof(_v.tupleof[idx]))(name, tooltip, _v.tupleof[idx]))
                changesInMembers = true;
        }

        return changesInMembers;
    }

    private static bool renderEditor(T)(string _fieldname, const(char)* _tooltip, ref T _v)
        if(is(T : P*,P))
    {
        UEGui.Text("no editor for pointers: " ~ T.stringof ~ " ('" ~ _fieldname ~ "')");
        return false;
    }

    private static bool renderEditor(T)(string _fieldname, const(char)* _tooltip, ref T _v)
        if(is(T == struct) || (is(T == class) && !is(T:UEComponent) &&!is(T:UEEntity)))
    {
        UEGui.Text("no editor for: " ~ T.stringof ~ " ('" ~ _fieldname ~ "')");
        return false;
    }

    private static bool renderEditor(T)(string _fieldname, const(char)* _tooltip, ref T _v)
        if(is(T == class) && is(T:UEComponent))
    {
        UEGui.Text(_fieldname ~ ": \"" ~ _v.entity.name ~ "\"");
        return false;
    }

    private static bool renderEditor(T)(string _fieldname, const(char)* _tooltip, ref T _v)
        if(is(T == class) && is(T:UEEntity))
    {
        UEGui.Text(_fieldname ~ ": \"" ~ _v.name ~ "\"");
        return false;
    }

    private static bool renderEditor(T:E[],E)(string _fieldname, const(char)* _tooltip, ref T _v)
    {
        UEGui.Text("no editor for array: " ~ T.stringof ~ " ('" ~ _fieldname ~ "')");
        return false;
    }

    private static bool renderEditor(T:E[K],E,K)(string _fieldname, const(char)* _tooltip, ref T _v)
    {
        UEGui.Text("no editor for assoc.array: " ~ T.stringof ~ " ('" ~ _fieldname ~ "')");
        return false;
    }

    private static bool renderEditor(T:bool)(string _fieldname, const(char)* _tooltip, ref T _v)
    {
        auto changes = UEGui.checkbox(_fieldname, _v);

        if (_tooltip !is null && igIsItemHovered())
            igSetTooltip(_tooltip);

        return changes;
    }

    private static bool renderEditor(T)(string _fieldname, const(char)* _tooltip, ref T _v)
        if(is(T == float))
    {
        auto changes = UEGui.DragFloat(_fieldname, _v);
        
        if (_tooltip !is null && igIsItemHovered())
            igSetTooltip(_tooltip);

        return changes;
    }

    private static bool renderEditor(T)(string _fieldname, const(char)* _tooltip, ref T _v)
        if(is(T:int) && !is(T == enum))
    {
        int i = _v;
        auto changes = UEGui.DragInt(_fieldname, i);
        _v = i;
     
        if (_tooltip !is null && igIsItemHovered())
            igSetTooltip(_tooltip);

        return changes;
    }

    private static bool renderEditor(T)(string _fieldname, const(char)* _tooltip, ref T _v)
        if(is(T == enum))
    {
        auto changes = UEGui.EnumCombo(_fieldname, _v);

        if (_tooltip !is null && igIsItemHovered())
            igSetTooltip(_tooltip);

        return changes;
    }

    private static bool renderObjectEditor(T)(T _v)
    {
        auto changesInBase = renderBaseClasses!T(_v);
        auto changesInMembers = renderMembers!T(_v);

        return changesInBase || changesInMembers;
    }
        
    static class UEDefaultInspector(T) : IComponentEditor
    {
        override bool render(UEObject _component)
        {
            //pragma(msg, "\nEDITOR: "~T.stringof);

            auto thisT = cast(T)_component;

            return renderObjectEditor(thisT);    
        }
    }
}
else
{
    struct UEDefaultInspector(T){}
}