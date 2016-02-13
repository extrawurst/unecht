module unecht.core.components.editor.ui.dragDropEditor;

version(UEIncludeEditor):

import unecht.core.object;
import unecht.core.component;
import unecht.core.components.internal.gui;
import unecht.core.entity;

import derelict.imgui.imgui;

///
final class UEDragDropEditor : UEComponent 
{
    mixin(UERegisterObject!());
    
    private static UEObject object;
    private static bool validDrop;

    ///
    public static bool mayStartDrag(UEObject _obj)
    {
        if(igIsItemActive() && igIsMouseDragging(0))
        {
            object = _obj;
            return true;
        }
        return false;
    }

    ///
    public static void canDrop(TypeInfo _acceptType)
    {
        if (igIsItemHoveredRect() && object !is null)
        {
            validDrop = true;
        }
    }

    ///
    public static UEObject isDropped()
    {
        if (validDrop && igIsMouseReleased(0))
        {
            return object;
        }

        return null;
    }
    
    ///
    public void render()
    {
        if(igIsMouseReleased(0) && object !is null)
            object = null;

        if(object is null)
            return;

        ImVec2 v;
        igGetMousePos(&v);
        igSetNextWindowPos(v,ImGuiSetCond_Always);
        igBegin("drag",null,
            ImGuiWindowFlags_NoInputs|
            ImGuiWindowFlags_ShowBorders|
            ImGuiWindowFlags_AlwaysAutoResize|
            ImGuiWindowFlags_NoTitleBar);

        if(validDrop)
            igPushStyleColor(ImGuiCol_Text, ImVec4(0,1,0,1));

        UEGui.Text(object.typename);

        if(validDrop)
            igPopStyleColor();
        
        igEnd();

        validDrop = false;
    }
}
