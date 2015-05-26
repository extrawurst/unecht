module unecht.core.components.editor.commands;

version(UEIncludeEditor):

import unecht;

import unecht.core.components._editor;
import unecht.core.components.sceneNode;

///
abstract class UEEditorCommand
{
    void execute();
    void undo();
}

///
final class UECmdDelete : UEEditorCommand
{
private:
    import std.uuid;
    
    string itemData;
    UUID parentId;
    
    ///
    public override void execute()
    {
        assert(EditorRootComponent.currentEntity);
        
        UESerializer s;
        EditorRootComponent.currentEntity.sceneNode.serialize(s);
        
        itemData = s.toString();
        
        parentId = EditorRootComponent.currentEntity.sceneNode.parent.instanceId;
        
        UEEntity.destroy(EditorRootComponent.currentEntity);
        
        EditorRootComponent.selectEntity(null);
    }
    
    ///
    public override void undo()
    {
        UEDeserializer d = UEDeserializer(itemData);
        auto node = d.deserializeFirst!UESceneNode;
        
        auto obj = cast(UESceneNode)ue.scene.findObject(parentId);
        
        assert(obj);
        
        node.parent = obj;
        node.onCreate();
        
        EditorRootComponent.selectEntity(node.entity);
    }
}

///
struct UECommands
{
    static UEEditorCommand[] history;
    
    ///
    static void execute(UEEditorCommand cmd)
    {
        UEFibers.startFiber({
                Fiber.yield();
                cmd.execute();
                history ~= cmd;
            });
    }
    
    ///
    static void undo()
    {
        if(history.length>0)
        {
            UEFibers.startFiber({
                    Fiber.yield();
                    auto cmd = history[$-1];
                    cmd.undo();
                    history.length = history.length-1;
                });
        }
    }
}