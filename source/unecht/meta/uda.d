module unecht.meta.uda;

alias aliasHelper(alias T) = T;
alias aliasHelper(T) = T;

///
private template getUDAIndex(alias UDA, ATTR...)
{
    template findUDA(int i)
    {
        static if(ATTR.length == 0)
        {
            enum findUDA = -1;
        }
        else static if(i >= ATTR.length)
        {
            enum findUDA = -1;
        }
        else
        {
            static if(is(aliasHelper!(ATTR[i]) == UDA) || is(typeof(ATTR[i]) == UDA))
            {
                enum findUDA = i;
            }
            else
            {
                enum findUDA = findUDA!(i+1);
            }
        }
    }

    enum getUDAIndex = findUDA!(0);
}

///
template hasUDA(alias T, alias UDA)
{
    enum hasUDA = getUDAIndex!(UDA,__traits(getAttributes, T)) != -1;
}

///
template getUDA(alias T, alias UDA)
{
    template findUDA(ATTR...)
    {
        static if(hasUDA!(T, UDA))
        {
            enum findUDA = ATTR[getUDAIndex!(UDA, ATTR)];
        }
        else
        {
            import std.string:format;
            static assert(0, format("UDA '%s' not found for Type '%s'", UDA.stringof, T.stringof));
        }
    }
    enum getUDA = findUDA!(__traits(getAttributes, T));
}

unittest
{
    struct e{}

    struct A{
        @A
        string bar;
    }

    @e
    struct Foo
    {
        @A("foo")
        int i;
    }

    static assert(!hasUDA!(Foo, A));
    static assert(hasUDA!(Foo, e));
    static assert(hasUDA!(Foo.i, A));
    static assert(getUDA!(Foo.i, A).bar == "foo");

    //even UDA-Inception works :P
    static assert(hasUDA!(getUDA!(Foo.i, A).bar, A));
    static assert(!hasUDA!(getUDA!(Foo.i, A).bar, e));
}