#version 330

#define NORMAL_AMBIENT

#ifdef NORMAL_AMBIENT
vec3 ambient = vec3(0.1,0.1,0.1);
#else
vec3 ambient = vec3(0,0.6,0);
#endif

in Data {
    float shading;
} DataIn;

out vec4 Color;

void main(void)
{
	vec3 shadedAmbient = ambient + DataIn.shading;
	Color = vec4(shadedAmbient, 1.0);
}
