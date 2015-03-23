#version 330

uniform mat4 matWorld;
uniform vec3 v3ViewDir;

in vec3 Position;
in vec3 Normal;

out Data {
    //vec3 color;
    float shading;
} DataOut;

void main()
{
	gl_Position = matWorld * vec4(Position, 1.0);

	DataOut.shading = abs(dot(Normal, v3ViewDir));

	//DataOut.color = Normal;
}
