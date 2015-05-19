module unecht.core.components.editor.menus;

alias MenuItemFunc = void function();

struct EditorMenuItem
{
    string name;
    MenuItemFunc func;
}

/// UDA
struct MenuItem
{
    string name;
}