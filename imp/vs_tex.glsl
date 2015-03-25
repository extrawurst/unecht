#version 330

uniform mat4 matWorld;

in vec3 Position;
in vec2 Texcoord;

out Data {
	vec2 texcoord;
} DataOut;

void main()
{
	gl_Position = matWorld * vec4(Position, 1.0);
	
	DataOut.texcoord = Texcoord;
}
