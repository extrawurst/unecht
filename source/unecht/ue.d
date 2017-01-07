module unecht.ue;

import 
    unecht.core.types,
    unecht.core.scenegraph,
    unecht.core.application,
    unecht.core.events;

///
//alias DebugTickFunc = void function (double);
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