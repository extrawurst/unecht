#version 330

in Data {
    //vec3 color;
    float shading;
} DataIn;

out vec4 Color;

void main(void)
{
	Color = vec4(DataIn.shading,DataIn.shading,DataIn.shading, 1.0);
	//Color = vec4(DataIn.color, 1.0);
}
