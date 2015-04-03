#version 150

uniform vec4 globalColor = vec4(1,1,1,1);

out vec4 Color;

void main(void)
{
	Color = globalColor;
}
