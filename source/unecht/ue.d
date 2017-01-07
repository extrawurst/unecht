module unecht.ue;

import 
    unecht.core.types,
    unecht.core.scenegraph,
    unecht.core.application,
    unecht.core.events;

///
alias ActionFunc = void function ();

//TODO: get rid and replace with decent DI container
/// root object currently containing singletons that need to be accessable from everywhere.
/// this will change as soon as a DI container is in place.
struct Unecht
{
	///
	UEWindowSettings windowSettings;
	///
	UEScenegraph scene;
	///
	UEApplication application;
	///
	UEEvents events;
	///
	ActionFunc hookStartup;
	///
	float tickTime = 0;
}

///
__gshared Unecht ue;