#version 150

uniform mat4 matWorld;

in vec3 Position;

void main()
{
	gl_Position = matWorld * vec4(Position, 1.0);
}
