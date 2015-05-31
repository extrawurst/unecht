module unecht.core.components.editor.editorMenus;

version(UEIncludeEditor):

import unecht;

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
    @MenuItem("main/new scene")
    private static void newScene()
    {
        import unecht.core.hideFlags;

        EditorRootComponent.selectEntity(null);

        foreach(rootChild; ue.scene.root.children)
        {
            if(!rootChild.hideFlags.isSet(HideFlags.hideInHirarchie))
                UEEntity.destroy(rootChild.entity);
        }
    }

    ///
    @MenuItem("main/load scene")
    private static void loadScene()
    {
        import unecht.core.hideFlags;
        import unecht.core.serialization.sceneSerialization;

        UEFibers.startFiber({
                UEEditorMenus.newScene();
                Fiber.yield();
                UESceneDeserializer d = UESceneDeserializer(UEEditorMenus.loadFromFile("assets/dummy.scene"));
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

                UESceneSerializer s;
               
                s.serialize(ue.scene.root);

                saveToFile("assets/dummy.scene", s.toString());
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
    @MenuItem("entity/add entity")
    private static void addEmptyEntity()
    {
        UEEntity.create("new entity",EditorRootComponent.currentEntity?EditorRootComponent.currentEntity.sceneNode:null);
    }
    
    ///
    @MenuItem("entity/clone entity", &entitySelected)
    private static void cloneEntity()
    {
        assert(EditorRootComponent.currentEntity);
        
        UESerializer s;
        EditorRootComponent.currentEntity.sceneNode.serialize(s);

        UEDeserializer d = UEDeserializer(s.toString);
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