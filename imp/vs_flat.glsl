#version 150

uniform mat4 matWorld;

in vec3 position;

void main()
{
	gl_Position = matWorld * vec4(position, 1.0);
}
