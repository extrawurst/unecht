module unecht.core.components.editor.ui.menuSystem;

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
            auto open = igBeginMenu(this.entity.name.toStringz);
            scope(exit){if(open)igEndMenu();}
            
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
                
                if(igMenuItem(this.entity.name.toStringz,"",false,isValid))
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

import unecht.core.assets.texture;

///
final class UEEditorMenuBar : UEComponent 
{
    mixin(UERegisterObject!());

    static ImVec2 _size;

    static @property float height() { return _size.y; }

    private static ubyte[] texImg = cast(ubyte[])import("playbuttons.png");

    private UETexture2D tex;
    
    override void onCreate() {
        super.onCreate;
        
        tex = new UETexture2D();
        tex.loadFromMemFile(texImg);

        addMenuItem("main", sceneNode);
        addMenuItem("edit", sceneNode);
        addMenuItem("assets", sceneNode);
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
        auto menuBar = igBeginMainMenuBar();
        igGetWindowSize(&_size);
        scope(exit){if(menuBar)igEndMainMenuBar();}
        
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

        auto buttonHeight = 22;

        if(igImageButton(tex.driverHandle, ImVec2(buttonHeight,buttonHeight), ImVec2(0,0), ImVec2(0.5f,1)))
            ue.scene.playing = true;

        igSameLine();
        
        if(ue.scene.playing)
        {
            if(igImageButton(tex.driverHandle, ImVec2(buttonHeight,buttonHeight), ImVec2(0.5f,0), ImVec2(1,1)))
                ue.scene.playing = false;
        }
        else
        {
            if(igButton("step"))
                ue.scene.step;
        }

        igSameLine();

        if(!ue.scene.playing)
            UEGui.DisabledButton("stop");
        //TODO: implement
        else if(UEGui.Button("stop"))
            ue.scene.playing = false;
    }
}