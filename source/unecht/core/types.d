module unecht.core.types;

///
struct Pos
{
	int left;
	int top;
}

///
struct Size
{
	int width;
	int height;
}

///
struct WindowSettings
{
	Size size = Size(128,128);
	string title = "unecht";
}