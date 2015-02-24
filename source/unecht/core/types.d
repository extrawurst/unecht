module unecht.core.types;

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
struct UEWindowSettings
{
	UESize size = UESize(128,128);
	string title = "unecht";
}