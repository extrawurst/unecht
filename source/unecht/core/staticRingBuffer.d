/++
 + Authors: Stephan Dilly, lastname dot firstname at gmail dot com
 + Copyright: MIT
 +/
module unecht.core.staticRingBuffer;

///
struct StaticRingBuffer(size_t size,T)
{
	///
	enum StaticSize = size;

	alias ThisType = StaticRingBuffer!(StaticSize,T);

	private T[size] data;
	private size_t spaceUsed;

	///
	ref ThisType opOpAssign(string op)(T v) @trusted
		if(op == "~")
	{
		if(spaceUsed < StaticSize)
		{
			data[spaceUsed++] = v;
		}
		else
		{
			import core.stdc.string:memmove;
			memmove(data.ptr, data.ptr+1, (StaticSize-1) * T.sizeof);
			data[StaticSize-1] = v;
		}

		return this;
	}

	///
	T opIndex(size_t idx)
	{
		if(idx >= spaceUsed)
			throw new Exception("idx out of range");

		return data[idx];
	}

	///
	@property size_t length() const { return spaceUsed; }

	///
	@property T* ptr() { return data.ptr; }
}

///
unittest
{
	StaticRingBuffer!(2,int) foo;
	assert(foo.length == 0);

	foo ~= 1;

	assert(foo.length == 1);
	assert(foo[0] == 1);

	foo ~= 2;

	assert(foo.length == 2);
	assert(foo[0] == 1);
	assert(foo[1] == 2);

	foo ~= 3;

	assert(foo.length == 2);
	assert(foo[0] == 2);
	assert(foo[1] == 3);
}
