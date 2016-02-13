module unecht.core.components.editor.editorGui;

version(UEIncludeEditor):

import unecht;

import unecht.core.component;
import unecht.core.components._editor;
import unecht.core.components.sceneNode;
import unecht.core.components.editor.ui.assetView;
import unecht.core.components.editor.ui.menuSystem;
import unecht.core.components.editor.ui.console;
import unecht.core.components.editor.ui.referenceEditor;
import unecht.core.components.editor.ui.dragDropEditor;

import derelict.imgui.imgui;

///
final class UEEditorGUI : UEComponent 
{
    mixin(UERegisterObject!());

    UEEditorMenuBar menuBar;
    UEEditorAssetView assetView;
    UEEditorConsole console;
    UEReferenceEditor referenceEditor;
    UEDragDropEditor dragDropEditor;

    override void onCreate() {
        super.onCreate;

        assetView = entity.addComponent!UEEditorAssetView;
        menuBar = entity.addComponent!UEEditorMenuBar;
        console = entity.addComponent!UEEditorConsole;
        referenceEditor = entity.addComponent!UEReferenceEditor;
        dragDropEditor = entity.addComponent!UEDragDropEditor;
    }

    //TODO: #127
    void render() {
        
        {
            const height = igGetItemsLineHeightWithSpacing();
            igSetNextWindowPos(ImVec2(0,ue.application.mainWindow.size.height-height),ImGuiSetCond_Always);
            
            igPushStyleColor(ImGuiCol_WindowBg, ImVec4(1,1,1,0));
            igBegin("editor",null,
                ImGuiWindowFlags_AlwaysAutoResize|
                ImGuiWindowFlags_NoTitleBar|
                ImGuiWindowFlags_NoMove);
            
            scope(exit) 
            { 
                igEnd();
                igPopStyleColor();
            }
            
            UEGui.Text(format("EditorMode (%s with F1) [%0.1f fps]",EditorRootComponent.visible?"hide":"show",igGetIO().Framerate));
        }
        
        if(EditorRootComponent.visible)
        {
            menuBar.render();
            if(showHirarchie)
            {
                renderScene();
                renderInspector();
            }
            if(showDebug)
                renderDebug();

            assetView.render(sceneWindowHeight);

            if(console.enabled)
                console.render();

            referenceEditor.render();

            dragDropEditor.render();
        }
    }

    private static void renderDebug()
    {
        igBegin("debug", &showDebug);
        scope(exit) igEnd();

        import unecht.core.profiler;
        igPlotLines("framestimes",UEProfiling.frameTimes.ptr,cast(int)UEProfiling.frameTimes.length,0,null,float.max,float.max,ImVec2(0,100));
        igPlotLines("fps",UEProfiling.framerates.ptr,cast(int)UEProfiling.framerates.length,0,null,float.max,float.max,ImVec2(0,100));
    }

    ///
    package static bool showHirarchie = true;
    package static bool showDebug = false;

    private static float sceneWindowWidth;
    private static float sceneWindowHeight;
    ///
    private static void renderScene()
    {
		const top = igGetItemsLineHeightWithSpacing();
        igSetNextWindowPos(ImVec2(0,top), ImGuiSetCond_Always);
        
        igBegin("scene",null,ImGuiWindowFlags_NoMove);
        scope(exit){igEnd();}

        foreach(n; ue.scene.root.children)
        {
            renderSceneNode(n);
        }
        
        sceneWindowWidth = igGetWindowWidth();
        sceneWindowHeight = igGetWindowHeight();
    }

    ///
    private static void renderSceneNode(UESceneNode _node)
    {
        if(_node.hideInHirarchie)
            return;
        
        const canExpand = _node.children.length>0;
        
        if(canExpand)
        {
            const expanded = UEGui.TreeNode(cast(void*)(_node.entity), _node.entity.name);
            
            if(igIsItemActive())
            {
                if(EditorRootComponent.currentEntity !is _node.entity)
                    EditorRootComponent.selectEntity(_node.entity);
            }
            if(igIsItemHovered() && igIsMouseDoubleClicked(0))
                EditorRootComponent.lookAtNode(_node);
            
            if(!expanded)
                return;
            
            foreach(n; _node.children)
            {
                renderSceneNode(n);
            }
            
            igTreePop();
        }
        else
        {
            igBullet();
            igPushIdPtr(cast(void*)(_node.entity));
            auto isSelected = EditorRootComponent.currentEntity is _node.entity;
            if(UEGui.Selectable(_node.entity.name,isSelected))
            {
                if(isSelected)
                    EditorRootComponent.selectEntity(null);
                else
                    EditorRootComponent.selectEntity(_node.entity);
            }
            igPopId();

            if(igIsItemHovered() && igIsMouseDoubleClicked(0))
                EditorRootComponent.lookAtNode(_node);
        }
    }

    ///
    private static void renderInspector()
    {
        if(!EditorRootComponent.currentEntity)
            return;

        const top = igGetItemsLineHeightWithSpacing();
        igSetNextWindowPos(ImVec2(sceneWindowWidth+1,top),ImGuiSetCond_Always);
        bool closed;
        igBegin("inspector",&closed,
            ImGuiWindowFlags_AlwaysAutoResize|
            ImGuiWindowFlags_NoCollapse|
            ImGuiWindowFlags_NoMove|
            ImGuiWindowFlags_NoResize);
        
        scope(exit)igEnd();
        
        if(closed)
        {
            EditorRootComponent.selectEntity(null);
            return;
        }
        
        string name = EditorRootComponent.currentEntity.name;
        UEGui.InputText("name",name);
        EditorRootComponent.currentEntity.name = name;
        
        foreach(int i, c; EditorRootComponent.currentEntity.components)
        {                
            const isSceneNode = i == 0;
            renderInspectorComponent(c,isSceneNode);
        }
        
        renderInspectorFooter();

		if(component2Remove)
		{
            //TODO: broken ?
			component2Remove.entity.removeComponent(component2Remove);
			component2Remove = null;
		}
        if(componentToAdd.length>0)
        {
            EditorRootComponent.currentEntity.addComponent(componentToAdd);
            componentToAdd.length = 0;
        }
    }

    ///
    private static void renderInspectorComponent(UEComponent c, bool isSceneNode)
    {
        auto openNode = false;

        if(!isSceneNode)
        {
            igPushIdPtr(cast(void*)c);
            openNode = UEGui.TreeNode(c.typename);
        }
        else
        {
            UEGui.Text("UESceneNode");
        }

        if(openNode || isSceneNode)
        {
            if(!openNode)
                igIndent();
            
            renderInspectorSameline(c);
            
            import unecht.core.componentManager;
            if(auto renderer = c.typename in UEComponentsManager.editors)
            {
                renderer.render(c);
            }
            
            if(openNode)
                igTreePop();
            else
                igUnindent();
        }
        else
        {
            renderInspectorSameline(c);
        }
        
        if(isSceneNode)
            igSeparator();
        else
            igPopId();
    }
    
	static UEComponent componentEdit;
    private static void renderInspectorSameline(UEComponent c)
    {
        auto subtext = " ";
        if(c.enabled)
            subtext = "X";

        ImVec2 size;
        igGetWindowContentRegionMax(&size);
        const wndWidth = cast(int)size.x;

		igCalcTextSize(&size,"#");
        const charWidth = 2 + cast(int)size.x*2;

        igSameLine(wndWidth-charWidth*2);
        if(UEGui.SmallButton("#"))
        {
			componentEdit = c;
            igOpenPopup("compedit");
        }

		renderComponentEdit();

        igSameLine(wndWidth - charWidth);
        if(UEGui.SmallButton(subtext))
            c.enabled = !c.enabled;
    }

	static UEComponent component2Remove;

	private static void renderComponentEdit()
	{
        bool menuOpen = igBeginPopup("compedit");
        scope(exit){ if(menuOpen) igEndPopup(); }

        if(!menuOpen && !componentEdit)
		{
            igCloseCurrentPopup();
			componentEdit = null;
			return;
		}
        if(menuOpen)
        {
            UEGui.Text("edit");
    		igSeparator();

    		if(UEGui.Button("remove"))
    		{
    			component2Remove = componentEdit;
    			componentEdit = null;
                igCloseCurrentPopup();
    		}
        }
	}

    static string componentToAdd;

    private static void renderInspectorFooter()
    {
        igSeparator();
        if(UEGui.Button("add  component..."))
            igOpenPopup("addcomp");
            
        static string filterString;

        bool menuOpen=igBeginPopup("addcomp");
        scope(exit){if(menuOpen) igEndPopup();}
        if(!menuOpen)
        {
            filterString.length=0;
            return;
        }
        else
        {
            UEGui.InputText("filter",filterString);
            igSeparator();

            import unecht.core.componentManager;
            foreach(c; UEComponentsManager.componentNames)
            {
                import std.string;
                if(c.indexOf(filterString,CaseSensitive.no)==-1)
                    continue;

                if(UEGui.Selectable(c,false))
                {
                    componentToAdd = c;
                    filterString.length=0;
                }
            }
        }
    }
}