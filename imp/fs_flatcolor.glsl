#version 150

in vec3 col;

out vec4 Color;

void main(void)
{
	Color = vec4(col,1);
}
