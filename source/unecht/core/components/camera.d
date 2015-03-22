module unecht.core.components.camera;

import unecht.core.component;

import gl3n.linalg;
import std.math;

//TODO: make component
/// 
final class Camera
{
	vec3 pos;
	vec3 dir = vec3(0,0,1);
	vec3 up = vec3(0,1,0);

	mat4 matProjection;
	mat4 matLook;

	float fieldOfView = PI / 4;
	float clipNear = 1;
	float clipFar = 1000;

	void updateLook()
	{
		auto target = pos + dir;

		matLook = mat4.look_at(
			pos,
			target,
			up);
	}

	void updateProjection()
	{
		matProjection = mat4.perspective(1024,768,fieldOfView,clipNear,clipFar);
	}
}