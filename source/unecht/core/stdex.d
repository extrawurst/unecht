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
auto testBit(T)(in T v, size_t bitIdx)
{
    auto bitMask = 1<<bitIdx;
    return (v & bitMask) == bitMask;
}

///
auto testBitMask(T)(in T v, size_t bitMask)
{
    return (v & bitMask) == bitMask;
}

unittest
{
    assert(testBitMask(0,1) == false);
    assert(testBitMask(1,1) == true);
    assert(testBitMask(0b10,0b10) == true);
    assert(testBitMask(0b1010,0b10) == true);
    assert(testBitMask(0b1010,0b1) == false);
    assert(testBitMask(0b1010,0b100) == false);
}