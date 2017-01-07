module unecht.core.components.editor.menuItems;

version(UEIncludeEditor):

import unecht.ue;
import unecht.core.fibers;
import unecht.core.entity;
import unecht.core.component;
import unecht.core.components._editor;
import unecht.core.components.sceneNode;
import unecht.core.components.editor.commands;

///
final class UEEditorMenus : UEComponent 
{
    mixin(UERegisterObject!());

    private static void saveToFile(string filename, string content)
    {
        import std.file;
        write(filename, content);
    }
    static string loadFromFile(string filename)
    {
        import std.file;
        return cast(string)read(filename);
    }

    ///
    private static bool entitySelected()
    {
        return EditorRootComponent.currentEntity !is null;
    }

    ///
    @MenuItem("assets/refresh")
    private static void assetsRefresh()
    {
        import unecht.core.assetDatabase:UEAssetDatabase;

        UEAssetDatabase.refresh();
    }
    
    ///
    @MenuItem("main/new scene")
    private static void newScene()
    {
        UEFibers.startFiber({
            import unecht.core.hideFlags;

            EditorRootComponent.selectEntity(null);

            foreach(rootChild; ue.scene.root.children)
            {
                if(!rootChild.hideFlags.isSet(HideFlags.hideInHirarchie))
                    UEEntity.destroy(rootChild.entity);
            }
        });
    }

    ///
    @MenuItem("main/load scene")
    private static void loadScene()
    {
        import unecht.core.hideFlags;
        import unecht.core.serialization.sceneSerialization;
        import unecht.core.components.editor.ui.fileDialog:UEFileDialog;
        import unecht.core.assetDatabase:UEAssetDatabase;
        import std.string:format;

        UEFibers.startFiber({

                UEFileDialog.open("*.scene", ".scene");

                while(UEFileDialog.isOpen)
                    Fiber.yield;

                if(!UEFileDialog.wasOk)
                    return;

                UEEditorMenus.newScene();
                Fiber.yield();

                assert(ue.scene.root.children.length == 3, format("rootchildren: %s",ue.scene.root.children.length));

                UESceneDeserializer d = UESceneDeserializer(UEEditorMenus.loadFromFile(UEFileDialog.path));

                foreach(asset; UEAssetDatabase.assets)
                {
                    d.addExternalObj(asset.obj);
                }

                d.deserialize(ue.scene.root);
            });
    }

    ///
    @MenuItem("main/save scene")
    private static void saveScene()
    {
        UEFibers.startFiber({
                import unecht.core.hideFlags;
                import unecht.core.serialization.sceneSerialization;
                import unecht.core.components.editor.ui.fileDialog;
                import unecht.core.assetDatabase:UEAssetDatabase;

                UESceneSerializer s;
               
                s.serialize(ue.scene.root, UEAssetDatabase.getAllIds());

                UEFileDialog.open("*.scene", "scene");

                while(UEFileDialog.isOpen)
                    Fiber.yield;

                if(!UEFileDialog.wasOk)
                    return;

                saveToFile(UEFileDialog.path, s.toString());
            });
    }

    ///
    @MenuItem("main/quit")
    private static void quit()
    {
        ue.application.terminate();
    }

    ///
    @MenuItem("edit/undo")
    public static void undo()
    {
        UECommands.undo();
    }

    ///
    version(UEProfiling) 
    @MenuItem("view/profiler")
    private static void viewProfiler()
    {
        ue.application.openProfiler();
    }

    ///
    @MenuItem("view/hirarchie")
    private static void viewHirarchie()
    {
        import unecht.core.components.editor.editorGui;
        UEEditorGUI.showHirarchie = !UEEditorGUI.showHirarchie;
    }

    ///
    @MenuItem("view/debug")
    private static void viewDebug()
    {
        import unecht.core.components.editor.editorGui;
        UEEditorGUI.showDebug = !UEEditorGUI.showDebug;
    }

    ///
    @MenuItem("entity/add entity")
    private static void addEmptyEntity()
    {
        UEEntity.create("new entity",EditorRootComponent.currentEntity?EditorRootComponent.currentEntity.sceneNode:null);
    }
    
    ///
    @MenuItem("entity/clone entity", &entitySelected)
    private static void cloneEntity()
    {
        import unecht.core.assetDatabase:UEAssetDatabase;
        
        assert(EditorRootComponent.currentEntity);
        
        UESerializer s;
        s.externals = UEAssetDatabase.getAllIds();
        EditorRootComponent.currentEntity.sceneNode.serialize(s);

        UEDeserializer d = UEDeserializer(s.toString);
        foreach(asset; UEAssetDatabase.assets)
        {
            d.addExternalObj(asset.obj);
        }

        auto node = d.deserializeFirst!UESceneNode;
        d.createNewIds();

        node.parent = EditorRootComponent.currentEntity.sceneNode.parent;
        node.entity.name = node.entity.name~'_';
        node.onCreate();

        EditorRootComponent.selectEntity(node.entity);
    }

    ///
    @MenuItem("entity/save entity", &entitySelected)
    private static void saveEntity()
    {
        assert(EditorRootComponent.currentEntity);
        
        UESerializer s;
        EditorRootComponent.currentEntity.sceneNode.serialize(s);
        saveToFile("assets/dummy.entity", s.toString());
    }

    ///
    @MenuItem("entity/delete Entity", &entitySelected)
    public static void removeCurrentEntity()
    {
        UECommands.execute(new UECmdDelete());
    }
}
