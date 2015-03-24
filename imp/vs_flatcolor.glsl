#version 150

uniform mat4 matWorld;

in vec3 Position;
in vec3 Color;

out vec3 col;

void main()
{
	gl_Position = matWorld * vec4(Position, 1.0);
	col = Color;
}
