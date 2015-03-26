#version 330

uniform mat4 matWorld;
uniform vec3 v3ViewDir;

in vec3 position;
in vec3 normal;

out Data {
    //vec3 color;
    float shading;
} DataOut;

void main()
{
	gl_Position = matWorld * vec4(position, 1.0);

	DataOut.shading = abs(dot(normal, v3ViewDir));

	//DataOut.color = Normal;
}
