module unecht.core.components.misc;

import unecht.core.component;

/// 
final class UEMesh : UEComponent
{
	///
	void setDefaultRect() 
	{
		//TODO:
	}
}

/// 
final class UEMaterial : UEComponent
{

}

/// 
final class UERenderer : UEComponent
{
	UEMaterial material;
	UEMesh mesh;
}