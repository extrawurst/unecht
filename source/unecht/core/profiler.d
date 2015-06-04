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

    static float[128] frameTimes;

    static int frameIdx;

    static addFrametime(TickDuration d)
    {
        long durUSecs = d.usecs;

        if(frameIdx < frameTimes.length)
            frameTimes[frameIdx++] = durUSecs;
        else
        {
            import core.stdc.string:memmove;
            memmove(frameTimes.ptr, frameTimes.ptr+1, (frameTimes.length-1)*float.sizeof);
            frameTimes[frameTimes.length-1] = durUSecs;
        }
    }
}