module unecht.appmain;

version(unittest){}
else:
int main()
{
	import unecht;

	return ue.application.run();
}