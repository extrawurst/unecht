module unecht.meta.uda;

import std.format:format;

///
private struct UDASearchResult(alias UDA)
{
    alias value = UDA;
    bool found = false;
    value val;
}

///
auto getUDA(alias T, alias UDA)()
{
    enum res = findUDA!(T,UDA);
    static if(res.found)
    {
        return res.val;
    }
    else
    {
        static assert(0,.format("UDA '%s' not found for Type '%s'", UDA.stringof, T.stringof));
    }
}

///
private auto findUDA(alias T,alias UDA)()
{
    foreach(attr; __traits(getAttributes, T))
    {
        static if(is(typeof(attr) == UDA))
        {
            return UDASearchResult!UDA(true,attr);
        }
    }
    
    return UDASearchResult!UDA(false,UDA.init);
}