module unecht.core.components.editor.ui.assetView;

version(UEIncludeEditor):

import unecht;

import unecht.core.component;
import unecht.core.components._editor;
import unecht.core.components.sceneNode;
import unecht.core.components.editor.ui.assetInspector;
import unecht.core.components.editor.ui.dragDropEditor;
import unecht.core.assetDatabase;

import derelict.imgui.imgui;

///
final class UEEditorAssetView : UEComponent 
{
    mixin(UERegisterObject!());

    private static bool visible=true;

    @MenuItem("view/assets")
    private static void viewAssets() { visible = !visible; }

    static UEEditorAssetInspector inspector;

    override void onCreate() {
        super.onCreate;

        inspector = entity.addComponent!UEEditorAssetInspector;
    }

    //TODO: #127
    void render(float top)
    {
        if(!visible)
        {
            inspector.reset();
            return;
        }

        top += igGetItemsLineHeightWithSpacing()+1;

        igSetNextWindowPos(ImVec2(0,top), ImGuiSetCond_Always);
        igBegin("assets", &visible, ImGuiWindowFlags_NoCollapse|ImGuiWindowFlags_NoMove);
        scope(exit) igEnd();

        foreach(a; UEAssetDatabase.assets)
        {
            if(UEGui.Selectable(a.path,false))
            {
                inspector.asset = a;
            }

            UEDragDropEditor.mayStartDrag(a.obj);
        }

        inspector.render(igGetWindowWidth()+1, top);
    }
}