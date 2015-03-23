module unecht.core.componentManager;

import unecht.core.component;

version(UEIncludeEditor)
{
///
interface IComponentEditor
{	
	void render(UEComponent _component);
}

///
static struct UEComponentsManager
{
	static IComponentEditor[string] editors;
}
}