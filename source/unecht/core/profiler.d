module unecht.core.profiler;

version(UEProfiling)
{
	public import tharsis.prof;

	///
	Profiler profiler;

	/// Get 2 MB more than the minimum (maxEventBytes). Could also use malloc() here.
	ubyte[] storage = new ubyte[Profiler.maxEventBytes + 1024 * 1024 * 2];
}

///
static struct UEProfiling
{
	import std.datetime:TickDuration;
	import unecht.core.staticRingBuffer:StaticRingBuffer;

	///
	static StaticRingBuffer!(128,float) frameTimes;
	///
	static StaticRingBuffer!(128,float) framerates;

	///
	static addFrametime(TickDuration d, float framerate)
	{
		immutable durUSecs = d.usecs;

		frameTimes ~= durUSecs;
		framerates ~= framerate;
	}
}
