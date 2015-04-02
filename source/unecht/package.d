module unecht;

public import unecht.core.types;
public import unecht.core.events;
public import unecht.core.entity;
public import unecht.core.stdex;
public import unecht.core.scenegraph;
public import unecht.core.component;
public import unecht.core.components.physics;
public import unecht.core.components.shapes;

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
	DebugTickFunc[] debugTick;
	UEScenegraph scene;
	UEApplication application;
	UEEvents events;
	ActionFunc hookStartup;
	float tickTime;
	vec2 mousePos;
	bool mouseDown;
}

__gshared Unecht ue;
