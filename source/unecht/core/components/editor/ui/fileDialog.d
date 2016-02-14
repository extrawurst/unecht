module unecht.core.components.editor.ui.fileDialog;

version(UEIncludeEditor):

import unecht.core.component;
import unecht.core.components.internal.gui;

import derelict.imgui.imgui;

import std.file;
import std.path;

///
final class UEFileDialog : UEComponent 
{
    mixin(UERegisterObject!());

    static bool isOpen;
    static string path;
    static bool wasOk;
    private static string currentFile;
    private static string pattern;
    private static string extension;
    private static DirEntry[] dirList;
    private static string renameSource;
    private static string renameTarget;

    ///
    public static void open(string _pattern, string _extension)
    {
        currentFile.length = 0;
        isOpen = true;
        wasOk = true;
        pattern = _pattern;
        extension = _extension;

        update(getcwd()~"/");
    }

    private static update(string _path)
    {
        import std.path:dirName,relativePath;

        path = isDir(_path) ? _path : dirName(_path);
        dirList.length = 0;

        foreach (DirEntry e; dirEntries(path, SpanMode.shallow))
        {
            if(e.isDir || (e.isFile && globMatch(e.name,pattern)))
                dirList ~= e;
        }
    }

    public void render()
    {
        if(!isOpen)
            return;

        igOpenPopup("file dialog");

        if(igBeginPopupModal("file dialog"))
        {
            scope(exit){igEndPopup();}

            UEGui.Text("path: "~path);
            UEGui.Text("pattern: "~pattern);
            igSeparator();

            if(UEGui.Button(".."))
            {
                path = buildNormalizedPath(path~"/..");
                update(path);
                return;
            }

            foreach(entry; dirList)
            {
                if(renameSource == entry.name)
                {
                    if(renderRename())
                        break;
                }
                else
                {
                    UEGui.Text(relativePath(entry.name,path));
                    if(igIsItemHovered())
                    {
                        if(entry.isDir)
                        {
                            if(igIsMouseDoubleClicked(0))
                            {
                                update(entry.name);
                                return;
                            }
                        }
                        else
                        {
                            if(igIsMouseClicked(0))
                            {
                                currentFile = baseName(entry);
                            }
                        }
                    }

                }
            }

            igSeparator();

            UEGui.InputText("filename", currentFile);

            igSeparator();

            if(igButton("new folder"))
            {
                import std.file:mkdir;
                mkdir(path~"/"~"new folder");
                update(path);
            }

            igSameLine();

            if(igButton("ok"))
            {
                path ~= "/"~currentFile;
                path = setExtension(path,extension);
                igCloseCurrentPopup();
                isOpen = false;
            }

            igSameLine();

            if(igButton("cancel"))
            {
                igCloseCurrentPopup();
                isOpen = false;
                wasOk = false;
            }
        }
    }

    private bool renderRename()
    {
        if(UEGui.InputText("rename",renameTarget))
        {
            import unecht.core.logger;
            import std.file:rename;
            log.logf("rename %s -> %s",renameSource,renameTarget);
            
            rename(renameSource,renameTarget);
            renameSource.length = 0;
            update(path);
            return true;
        }

        return false;
    }
}
