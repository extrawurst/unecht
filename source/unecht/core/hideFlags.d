module unecht.core.hideFlags;

import unecht.core.componentSerialization;

///
enum HideFlags : int
{
    none,
    hideInHirarchie = 1<<0,
    hideInInspector = 1<<1,
    dontSaveInScene = 1<<2,
}

///
alias HideFlagSet = UEFlags!HideFlags;

///
@CustomSerializer //TODO: see #86
struct UEFlags(E)
{
    import std.traits:OriginalType;
    import unecht.core.stdex;

    enum isBaseEnumType(T) = is(E == T);
    alias Base = OriginalType!E;
    //TODO: make private
    Base mValue;

    ///
    bool isSet(E v) const
    {
        return (mValue | v) == v;
    }

    ///
    void set(E v)
    {
        mValue = mValue | v;
    }
}

unittest
{
}