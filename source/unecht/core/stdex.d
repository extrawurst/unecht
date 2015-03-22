module unecht.core.stdex;

//TODO: allow unstable remove
///
auto removeElement(R,N)(R _haystack, N _needle)
{
	import std.algorithm:countUntil,remove;

	auto index = _haystack.countUntil(_needle);

	return (index != -1) ? _haystack.remove(index) : _haystack;
}

unittest
{
	auto arr = [1,5,10];
	arr = arr.removeElement(5);
	assert(arr == [1,10]);
}