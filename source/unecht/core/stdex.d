module unecht.core.stdex;

import std.algorithm;

//TODO: allow unstable remove
///
auto removeElement(R,N)(R _haystack, N _needle)
{
	auto index = _haystack.countUntil(_needle);
	
	if(index != -1)
		return _haystack.remove(index);

	return _haystack;
}