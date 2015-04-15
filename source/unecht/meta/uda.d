module unecht.meta.uda;

import std.string:format;

///
private struct UDASearchResult(alias UDA)
{
    alias value = UDA;
    bool found = false;
    value val;
}

///
template hasUDA(alias T, alias UDA)
{
    template isAny(ATTR...)
    {
        static if(ATTR.length == 0)
        {
            enum isAny=false;
        }
        else static if(ATTR.length == 1)
        {
            enum isAny = is(typeof(ATTR[0]) == UDA);
        }
        else
        {
            enum isAny = isAny!(ATTR[0]) || isAny!(ATTR[1..$]);
        }
    }

    enum hasUDA = isAny!(__traits(getAttributes, T));
}

///
template getUDATemplate(alias T, alias UDA)
{
    template idx(int i, ATTR...)
    {
        static if(ATTR.length == 0)
        {
            enum idx = -1;
        }
        else static if(i >= ATTR.length)
        {
            enum idx = -1;
        }
        else
        {
            enum idx = is(typeof(ATTR[i]) == UDA) ? i : idx!(i+1,ATTR);
        }
    }
    //static assert(idx!(0,__traits(getAttributes, T)) != -1);
    enum getUDATemplate = __traits(getAttributes, T)[idx!(0,__traits(getAttributes, T))];
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