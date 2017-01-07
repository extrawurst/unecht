module unecht;

public import unecht.ue;
public import unecht.core.application;
public import unecht.core.types;
public import unecht.core.events;
public import unecht.core.entity;
public import unecht.core.scenegraph;
//TODO: why do we have to import this here to include texture default inspector in static ctors...?!
public import unecht.core.assets.texture;
public import unecht.core.assetDatabase;
public import unecht.core.component;
public import unecht.core.components.physics;
public import unecht.core.components.shapes;
public import unecht.core.components.material;
public import unecht.core.components.internal.gui;
public import unecht.core.defaultInspector;
public import unecht.core.fibers;
version(UEIncludeEditor){
public import unecht.core.components.editor.menus;
public import unecht.meta.uda;
}

public import gl3n.linalg;

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
