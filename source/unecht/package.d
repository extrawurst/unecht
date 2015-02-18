module unecht;

struct WindowSettings
{
	int width = 128;
	int height = 128;
	string title = "unecht";
}

alias DebugTickFunc = void function (double);

struct Unecht
{
public:
	WindowSettings windowSettings;
	DebugTickFunc[] debugTick;
}

__gshared Unecht ue;