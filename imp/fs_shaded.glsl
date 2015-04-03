#version 330

const vec3 ambient = vec3(0.1,0.1,0.1);

uniform vec4 globalColor = vec4(1,1,1,1);

in Data {
    float shading;
} DataIn;

out vec4 Color;

void main(void)
{
	vec3 shadedAmbient = ambient + DataIn.shading;
	Color = vec4(shadedAmbient, 1.0) * globalColor;
}
