module unecht.core.components.editor.ui.assetInspector;

version(UEIncludeEditor):

import unecht;

import unecht.core.object;
import unecht.core.component;
import unecht.core.components._editor;
import unecht.core.components.sceneNode;
import unecht.core.assetDatabase;

import derelict.imgui.imgui;

///
final class UEEditorAssetInspector : UEComponent 
{
    mixin(UERegisterObject!());

    static UEAsset asset;

    static void reset() { asset = UEAsset.init; }

    //TODO: #127
    void render()
    {
        auto object = asset.obj;

        if(!object)
            return;
        
        bool closed;
        ig_Begin("asset inspector",&closed,
            //ImGuiWindowFlags_AlwaysAutoResize|
            ImGuiWindowFlags_NoCollapse
            //ImGuiWindowFlags_NoMove|
            //ImGuiWindowFlags_NoResize
            );
        
        scope(exit)ig_End();
        
        if(closed)
        {
            reset();
            return;
        }

        import std.string:format;
        UEGui.Text(format("%s (%s)",asset.path,asset.obj.typename));

        import unecht.core.componentManager;
        if(auto renderer = asset.obj.typename in UEComponentsManager.editors)
        {
            renderer.render(asset.obj);
        }
    }
}