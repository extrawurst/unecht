module unecht.core.components.editor.ui.assetView;

version(UEIncludeEditor):

import unecht;

import unecht.core.component;
import unecht.core.components._editor;
import unecht.core.components.sceneNode;
import unecht.core.components.editor.ui.assetInspector;
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
    void render()
    {
        if(!visible)
        {
            inspector.reset();
            return;
        }

        inspector.render();

        igBegin("assets", &visible);
        scope(exit) igEnd();

        foreach(a; UEAssetDatabase.assets)
        {
            if(UEGui.Selectable(a.path,false))
            {
                inspector.asset = a;
            }
        }
    }
}