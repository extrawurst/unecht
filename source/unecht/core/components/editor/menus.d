module unecht.core.components.editor.menus;

version(UEIncludeEditor):

alias MenuItemFunc = void function();
alias MenuItemValidateFunc = bool function();

///
struct EditorMenuItem
{
    string name;
    MenuItemFunc func;
    MenuItemValidateFunc validateFunc;
}

/// UDA
struct MenuItem
{
    string name;
    MenuItemValidateFunc validate;
}