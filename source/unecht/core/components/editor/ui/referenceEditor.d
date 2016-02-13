module unecht.core.components.editor.ui.referenceEditor;

version(UEIncludeEditor):

import unecht.core.object;
import unecht.core.component;
import unecht.core.components.internal.gui;
import unecht.core.assets.texture;
import unecht.core.entity;
import unecht.core.assetDatabase;

import derelict.imgui.imgui;

///
final class UEReferenceEditor : UEComponent 
{
    mixin(UERegisterObject!());
    
    private static UEObject* object;

    ///
    public static void open(UEObject* _obj)
    {
        object = _obj;
    }
    
    //TODO: filter using string
    //TODO: filter using target type
    ///
    void render()
    {
        if(object is null)
            return;

        igOpenPopup("ref");

        if(igBeginPopupModal("ref"))
        {
            scope(exit){igEndPopup();}

            foreach(asset; UEAssetDatabase.assets)
            {
                //import std.string;
                //if(c.indexOf(filterString,CaseSensitive.no)==-1)
                //    continue;

                if(UEGui.Selectable(asset.path,false))
                {
                    *object = asset.obj;
                    object = null;
                    //filterString.length=0;
                }
            }
        }
    }
}
