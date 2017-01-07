module unecht;

public import 
	unecht.ue,
	unecht.core.events,
	unecht.core.application,
	unecht.core.types,
	unecht.core.events,
	unecht.core.entity,
	unecht.core.scenegraph,
	//TODO: why do we have to import this here to include texture default inspector in static ctors...?!
	unecht.core.assets.texture,
	unecht.core.assetDatabase,
	unecht.core.component,
	unecht.core.components.physics,
	unecht.core.components.shapes,
	unecht.core.components.material,
	unecht.core.components.internal.gui,
	unecht.core.defaultInspector,
	unecht.core.fibers;

version(UEIncludeEditor){
public import 
	unecht.core.components.editor.menus,
	unecht.meta.uda;
}

public import 
	gl3n.linalg,
	gl3n.math;

public import std.typecons:scoped,Unique;

///
class UnechtException : Exception
{
	///
	this(string _str)
	{
		super(_str);
	}
}
