#version 150

uniform mat4 matWorld;

in vec3 position;
in vec3 color;

out vec3 col;

void main()
{
	gl_Position = matWorld * vec4(position, 1.0);
	col = color;
}
