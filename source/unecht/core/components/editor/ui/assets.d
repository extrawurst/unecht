module unecht.core.components.editor.ui.assets;

version(UEIncludeEditor):

import unecht;

import unecht.core.component;
import unecht.core.components._editor;
import unecht.core.components.sceneNode;
import unecht.core.assetDatabase;

import derelict.imgui.imgui;

///
final class UEEditorAssetView : UEComponent 
{
    mixin(UERegisterObject!());

    private static bool visible=false;

    ///
    @MenuItem("view/assets")
    private static void viewAssets()
    {

        visible = !visible;
    }

    //TODO: #127
    void render()
    {
        if(!visible)
            return;

        ig_Begin("assets");
        scope(exit) ig_End();

        foreach(a; UEAssetDatabase.assets)
        {
            if(UEGui.Selectable(a.path,false))
            {

            }
        }
    }
}