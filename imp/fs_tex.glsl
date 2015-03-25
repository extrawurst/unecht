#version 330

uniform sampler2D texture1;

in Data {
	vec2 texcoord;
} DataIn;

out vec4 Color;

void main(void)
{
	Color = texture(texture1, DataIn.texcoord);
}
