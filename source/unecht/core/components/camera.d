module unecht.core.components.camera;

import unecht.core.component;

import gl3n.linalg;
import std.math:PI_4;

//TODO: add properties and make matrix updates implicit
/// 
final class UECamera : UEComponent
{
	vec3 dir = vec3(0,0,1);
	vec3 up = vec3(0,1,0);

	mat4 matProjection;
	mat4 matLook;

	float fieldOfView = PI_4;
	float clipNear = 1;
	float clipFar = 1000;

	void updateLook()
	{
		auto target = entity.sceneNode.position + dir;

		matLook = mat4.look_at(
			entity.sceneNode.position,
			target,
			up);
	}

	void updateProjection()
	{
		matProjection = mat4.perspective(1024,768,fieldOfView,clipNear,clipFar);
	}
}