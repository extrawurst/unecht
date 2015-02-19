module unecht;

public import unecht.core.types;
public import unecht.core.events;
public import unecht.core.entity;
public import unecht.core.component;

import unecht.glfw.application;

class UnechtException : Exception
{
	this(string _str)
	{
		super(_str);
	}
}

alias DebugTickFunc = void function (double);

///
class Renderer : Component {
	
	override void onCreate() {
		super.onCreate;
		

	}

	override void onUpdate() {

		
	}
}

struct Unecht
{
	WindowSettings windowSettings;
	DebugTickFunc[] debugTick;
	Entity currentScene;
	string startComponent;
	Application application;
	Events events;
}

__gshared Unecht ue;
