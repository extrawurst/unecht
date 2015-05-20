module unecht.core.components.editor.editorMenus;

version(UEIncludeEditor):

import unecht;

import unecht.core.component;
import unecht.core.components._editor;
import unecht.core.components.sceneNode;

///
final class UEEditorMenus : UEComponent 
{
    mixin(UERegisterObject!());

    ///
    private static void saveToFile(string filename, string content)
    {
        import std.file;
        write(filename, content);
    }
    /+static string loadFromFile(string filename)
    {
        import std.file;
        return cast(string)read(filename);
    }+/

    ///
    private static bool entitySelected()
    {
        return EditorRootComponent.currentEntity !is null;
    }
    
    ///
    @MenuItem("add entity")
    private static void addEmptyEntity()
    {
        UEEntity.create("new entity",EditorRootComponent.currentEntity?EditorRootComponent.currentEntity.sceneNode:null);
    }

    ///
    @MenuItem("new scene")
    private static void newScene()
    {
        //UEEntity.create("new entity",EditorRootComponent.currentEntity?EditorRootComponent.currentEntity.sceneNode:null);
    }

    ///
    @MenuItem("save entity", &entitySelected)
    private static void saveEntity()
    {
        assert(EditorRootComponent.currentEntity);
        
        UESerializer s;
        EditorRootComponent.currentEntity.sceneNode.serialize(s);
        saveToFile("assets/dummy.entity", s.toString());
    }
    
    ///
    @MenuItem("clone entity", &entitySelected)
    private static void cloneEntity()
    {
        assert(EditorRootComponent.currentEntity);
        
        UESerializer s;
        EditorRootComponent.currentEntity.sceneNode.serialize(s);
        UEDeserializer d = UEDeserializer(s.toString);
        UESceneNode node = new UESceneNode;
        node.deserialize(d);
        node.parent = EditorRootComponent.currentEntity.sceneNode.parent;
        node.entity.name = node.entity.name~'_';
        node.onCreate();
    }
}