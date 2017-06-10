﻿/++
 + Authors: Stephan Dilly, lastname dot firstname at gmail dot com, @extrawurst
 + Copyright: MIT
 +/
module unecht.core.staticRingBuffer;

@safe @nogc:

///
struct StaticRingBuffer(size_t size,T)
{
	///
	enum StaticSize = size;

	alias ThisType = StaticRingBuffer!(StaticSize,T);

	private T[size] data;
	private size_t spaceUsed;

	///
	ref ThisType opOpAssign(string op)(T v) @trusted nothrow
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
		static immutable exc = new Exception("idx out of range");

		if(idx >= spaceUsed)
			throw exc;

		return data[idx];
	}

	///
	@property size_t length() const nothrow { return spaceUsed; }

	///
	@property T* ptr() { return &data[0]; }
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
