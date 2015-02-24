module unecht;

public import unecht.core.types;
public import unecht.core.events;
public import unecht.core.entity;
public import unecht.core.component;

public import unecht.glfw.application;

class UnechtException : Exception
{
	this(string _str)
	{
		super(_str);
	}
}

alias DebugTickFunc = void function (double);

///
class UERenderer : UEComponent {
	
	override void onCreate() {
		super.onCreate;
		

	}

	override void onUpdate() {

		
	}
}

struct Unecht
{
	UEWindowSettings windowSettings;
	DebugTickFunc[] debugTick;
	UEEntity currentScene;
	string startComponent;
	UEApplication application;
	UEEvents events;
}

__gshared Unecht ue;
