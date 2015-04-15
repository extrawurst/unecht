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

///
auto testBit(T)(in T v, size_t bit)
{
    return (v & bit) == bit;
}

unittest
{
    assert(testBit(0,1) == false);
    assert(testBit(1,1) == true);
    assert(testBit(0b10,0b10) == true);
    assert(testBit(0b1010,0b10) == true);
    assert(testBit(0b1010,0b1) == false);
    assert(testBit(0b1010,0b100) == false);
}