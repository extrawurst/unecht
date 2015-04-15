module unecht.core.types;

import gl3n.linalg;

///
struct UEPos
{
	int left;
	int top;
}

///
struct UESize
{
	int width;
	int height;
}

///
struct UERect
{
	UEPos pos;
	vec2 size = vec2(1);
}

///
struct UEWindowSettings
{
	UESize size = UESize(128,128);
	string title = "unecht";
}