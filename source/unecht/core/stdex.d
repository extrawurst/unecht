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

static if (__VERSION__ < 2067)
{
    ///
    auto clamp(T)(T _val, T _lower, T _upper)
    {
        if(_val < _lower)
            return _lower;
        else if(_val > _upper)
            return _upper;
        else
            return _val;
    }
}