module unecht.core.profiler;

version(UEProfiling)
{
    public import tharsis.prof;
    
    Profiler profiler;
    
    // Get 2 MB more than the minimum (maxEventBytes). Could also use malloc() here.
    ubyte[] storage = new ubyte[Profiler.maxEventBytes + 1024 * 1024 * 2];
}