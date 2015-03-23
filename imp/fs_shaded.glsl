#version 330

vec3 ambient = vec3(0.1,0.1,0.1);

in Data {
    //vec3 color;
    float shading;
} DataIn;

out vec4 Color;

void main(void)
{
	vec3 shadedAmbient = ambient + DataIn.shading;
	Color = vec4(shadedAmbient, 1.0);
	//Color = vec4(DataIn.color, 1.0);
}
