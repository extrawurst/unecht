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
    void render(float left, float top)
    {
        auto object = asset.obj;

        if(!object)
            return;

        igSetNextWindowPos(ImVec2(left,top), ImGuiSetCond_Always);

        bool closed;
        igBegin("asset inspector",&closed,
            //ImGuiWindowFlags_AlwaysAutoResize|
            ImGuiWindowFlags_NoCollapse|
            ImGuiWindowFlags_NoMove
            //ImGuiWindowFlags_NoResize
            );
        
        scope(exit)igEnd();
        
        if(closed)
        {
            reset();
            return;
        }

        import unecht.core.componentManager;
        if(auto renderer = asset.obj.typename in UEComponentsManager.editors)
        {
            auto changed = renderer.render(asset.obj);

            if(changed)
                UEAssetDatabase.updateAssetMetafile(asset.obj);
        }
        else
        {
            import unecht.core.logger;
            log.errorf("asset editor not found: %s",asset.obj.typename);
        }
    }
}