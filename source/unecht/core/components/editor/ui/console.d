module unecht.core.components.editor.ui.console;

version(UEIncludeEditor):

import unecht.core.component;
import unecht.core.components.internal.gui;
import unecht.core.components.editor.menus;

import derelict.imgui.imgui;

static if(__VERSION__ >= 2067)
    version = EnableConsole;

///
final class UEEditorConsole : UEComponent 
{
    mixin(UERegisterObject!());

    private static UEEditorConsole singleton;

    override void onCreate() {
        super.onCreate;
        singleton = this;
    }

    @MenuItem("view/console")
    static void MenuEnable()
    {
        singleton.enabled = !singleton.enabled;
    }

    //TODO: #127
    void render()
    {
        if(!enabled)
            return;

        bool open=true;
        igBegin("console", &open);
        scope(exit)igEnd();

        if(!open)
        {
            enabled = false;
            return;
        }

        version(EnableConsole)
            renderItems();
        else
            igText("this only works in versions compiled with D >= 2067");
    }

    version(EnableConsole)
    {
        import std.experimental.logger:LogLevel;

        static ImVec4 LogLevelToColor(LogLevel lvl)
        {
            final switch(lvl)
            {
                case LogLevel.trace:
                    return ImVec4(0.5,0.5,0.5,1);

                case LogLevel.warning:
                    return ImVec4(1,1,0,1);

                case LogLevel.error:
                    return ImVec4(0.8,0,0,1);
                case LogLevel.critical:
                case LogLevel.fatal:
                    return ImVec4(1,0,0,1);

                case LogLevel.info:
                case LogLevel.all:
                case LogLevel.off:
                    return ImVec4(1,1,1,1);
            }
        }

        void renderItems()
        {
            igBeginChild("ScrollingRegion");
            scope(exit) igEndChild();

            import unecht.core.logger;
            import std.experimental.logger;

            foreach(i; 0..logHistory.history.length)
            {
                const entry = logHistory.history[i];

                ImVec4 col = LogLevelToColor(entry.logLevel);

                igPushStyleColor(ImGuiCol_Text, col);
                scope(exit)igPopStyleColor();

                UEGui.Text(entry.msg);
            }
        }
    }
}