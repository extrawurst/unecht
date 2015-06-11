module unecht.core.components.editor.ui.menuBar;

version(UEIncludeEditor):

import unecht.core.component;
import unecht.core.components.sceneNode;
import unecht.core.entity;

import derelict.imgui.imgui;

///
final class UEEditorMenuItem : UEComponent 
{
    mixin(UERegisterObject!());
    
    import unecht.core.components.editor.menus;
    
    EditorMenuItem menuItem;
    
    void render()
    {
        import std.string:toStringz;
        
        if(sceneNode.children.length>0)
        {
            auto open = ig_BeginMenu(this.entity.name.toStringz);
            scope(exit){if(open)ig_EndMenu();}
            
            if(open)
            {
                foreach(c; sceneNode.children)
                {
                    auto subitem = c.entity.getComponent!UEEditorMenuItem;
                    if(subitem)
                        subitem.render();
                }
            }
        }
        else
        {
            if(menuItem.func)
            {
                auto isValid = menuItem.validateFunc?menuItem.validateFunc():true;
                
                if(ig_MenuItem(this.entity.name.toStringz,"",false,isValid))
                {
                    if(isValid)
                    {
                        menuItem.func();
                    }
                }
            }
        }
    }
}

///
final class UEEditorMenuBar : UEComponent 
{
    mixin(UERegisterObject!());
    
    override void onCreate() {
        super.onCreate;
        
        addMenuItem("main", sceneNode);
        addMenuItem("edit", sceneNode);
        addMenuItem("entity", sceneNode);
        
        import unecht.core.componentManager;
        
        foreach(ref m; UEComponentsManager.menuItems)
        {
            import std.string:split;
            auto pathElements = split(m.name, "/");
            
            attachItem(pathElements,m);
        }
    }
    
    private UEEditorMenuItem addMenuItem(string name, UESceneNode node)
    {
        auto e = UEEntity.create(name, node);
        return e.addComponent!UEEditorMenuItem;
    }
    
    private void attachItem(string[] path, EditorMenuItem menuItem)
    {
        assert(this.sceneNode);
        
        UESceneNode node = sceneNode;
        while(path.length > 1)
        {
            auto search = findMatchingMenu(path[0], node);
            if(!search)
            {
                search = addMenuItem(path[0], node);
            }
            
            assert(search);
            assert(search.sceneNode);
            
            path = path[1..$];
            node = search.sceneNode;
        }
        
        auto item = addMenuItem(path[0], node);
        item.menuItem = menuItem;
    }
    
    private UEEditorMenuItem findMatchingMenu(string name, UESceneNode node)
    {
        foreach(c; node.children)
        {
            auto item = c.entity.getComponent!UEEditorMenuItem;
            if(item)
            {
                if(item.entity.name == name)
                    return item;
            }
        }
        
        return null;
    }
    
    //TODO: #127
    void render()
    {
        auto menuBar = ig_BeginMainMenuBar();
        scope(exit){if(menuBar)ig_EndMainMenuBar();}
        
        if(menuBar)
        {
            foreach(c; sceneNode.children)
            {
                auto subitem = c.entity.getComponent!UEEditorMenuItem;
                if(subitem)
                    subitem.render();
            }

            renderControlButtons();
        }
    }

    private void renderControlButtons()
    {
        import unecht;

        if(ig_Button("play"))
            ue.scene.playing = true;

        ig_SameLine();
        
        if(ue.scene.playing)
        {
            if(ig_Button("pause"))
                ue.scene.playing = false;
        }
        else
        {
            if(ig_Button("step"))
                ue.scene.step;
        }
    }
}