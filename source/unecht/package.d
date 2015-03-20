module unecht;

public import unecht.core.types;
public import unecht.core.events;
public import unecht.core.entity;
public import unecht.core.scenegraph;
public import unecht.core.component;

public import unecht.glfw.application;

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
}

__gshared Unecht ue;
