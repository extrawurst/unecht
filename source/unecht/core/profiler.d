module unecht.core.profiler;

version(UEProfiling)
{
    public import tharsis.prof;

    Profiler profiler;

    // Get 2 MB more than the minimum (maxEventBytes). Could also use malloc() here.
    ubyte[] storage = new ubyte[Profiler.maxEventBytes + 1024 * 1024 * 2];
}

static struct UEProfiling
{
    import std.datetime;
    import unecht.core.staticRingBuffer;

    static StaticRingBuffer!(128,float) frameTimes;
    static StaticRingBuffer!(128,float) framerates;

    static int frameIdx;

    static addFrametime(TickDuration d, float framerate)
    {
        long durUSecs = d.usecs;

        frameTimes ~= durUSecs;
        framerates ~= framerate;
    }
}