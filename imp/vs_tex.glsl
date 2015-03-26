#version 330

uniform mat4 matWorld;

in vec3 position;
in vec2 texcoord;

out Data {
	vec2 texcoord;
} DataOut;

void main()
{
	gl_Position = matWorld * vec4(position, 1.0);
	
	DataOut.texcoord = texcoord;
}
