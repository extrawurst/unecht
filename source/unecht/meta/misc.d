module unecht.meta.misc;

///
template EnumMemberCount(T)
{
    enum EnumMemberCount = __traits(allMembers, T).length;
}