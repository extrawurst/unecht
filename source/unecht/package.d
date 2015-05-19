module unecht;

public import unecht.core.types;
public import unecht.core.events;
public import unecht.core.entity;
public import unecht.core.scenegraph;
public import unecht.core.component;
public import unecht.core.components.physics;
public import unecht.core.components.shapes;
public import unecht.core.components.material;
public import unecht.core.components.internal.gui;
public import unecht.core.defaultInspector;
version(UEIncludeEditor){
public import unecht.core.components.editor.menus;
public import unecht.meta.uda;
}

public import unecht.glfw.application;

public import gl3n.linalg;

public import std.typecons:scoped,Unique;

///
class UnechtException : Exception
{
	this(string _str)
	{
		super(_str);
	}
}

///
alias DebugTickFunc = void function (double);
///
alias ActionFunc = void function ();

///
struct Unecht
{
	UEWindowSettings windowSettings;
	UEScenegraph scene;
	UEApplication application;
	UEEvents events;
	ActionFunc hookStartup;
	float tickTime = 0;
}

__gshared Unecht ue;