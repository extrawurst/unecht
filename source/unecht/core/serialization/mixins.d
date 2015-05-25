module unecht.core.serialization.mixins;

///
mixin template generateObjectSerializeFunc(alias Func, SerializerType, string serializeFuncName)
{
    void iterateAllSerializables(T)(T v, ref SerializerType serializer)
    {
        import unecht.meta.uda;
        
        foreach(m; __traits(derivedMembers, T))
        {
            enum isMemberVariable = is(typeof(() {
                        __traits(getMember, v, m) = __traits(getMember, v, m).init;
                    }));
            
            enum isMethod = is(typeof(() {
                        __traits(getMember, v, m)();
                    }));
            
            enum isNonStatic = !is(typeof(&__traits(getMember, T, m)));
            
            //pragma(msg, .format("- %s (%s,%s,%s)",m,isMemberVariable,isNonStatic,isMethod));
            
            static if(isMemberVariable && isNonStatic && !isMethod) {
                
                enum hasSerializeUDA = hasUDA!(__traits(getMember, T, m), Serialize);
                
                //pragma(msg, .format("> '%s' (%s)", m, hasSerializeUDA));
                
                static if(hasSerializeUDA)
                {
                    alias M = typeof(__traits(getMember, v, m));
                    
                    enum hasCustomSerializerUDA = hasUDA!(__traits(getMember, T, m), CustomSerializer);
                    
                    static if(!hasCustomSerializerUDA)
                    {
                        Func!(T,M)(m, __traits(getMember, v, m), serializer);
                    }
                    else
                    {
                        enum customSerializerUDA = getUDA!(__traits(getMember, T, m), CustomSerializer);
                        
                        enum customSerializerTypeName = customSerializerUDA.serializerTypeName;
                        
                        Func!(T,M)(m, __traits(getMember, v, m), serializer, &__traits(getMember, mixin(customSerializerTypeName), serializeFuncName));
                    }
                }
            }
        }
    }
}