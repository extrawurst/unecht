module unecht.core.math.ray;

import gl3n.linalg;
import gl3n.aabb;

///
struct Ray(T)
{
    alias Vector!(T,3) VecType;
    VecType  origin = VecType(0,0,0);
    VecType  direction = VecType(0,0,0);

    /// note: fails for axis aligned rays (see: https://tavianator.com/fast-branchless-raybounding-box-intersections-part-2-nans/)
    public @nogc bool intersects(AABBT!T aabb, ref T distance) const
    {
        import std.algorithm:min,max;
        import std.math:abs;

        T tmin = -T.infinity;
        T tmax = T.infinity;
        
        if (direction.x != 0) 
        {
            auto t1 = (aabb.min.x - origin.x)/direction.x;
            auto t2 = (aabb.max.x - origin.x)/direction.x;
            
            tmin = max(tmin, min(t1, t2));
            tmax = min(tmax, max(t1, t2));
        }
        
        if (direction.y != 0) 
        {
            auto t1 = (aabb.min.y - origin.y)/direction.y;
            auto t2 = (aabb.max.y - origin.y)/direction.y;
            
            tmin = max(tmin, min(t1, t2));
            tmax = min(tmax, max(t1, t2));
        }

        if (direction.z != 0) 
        {
            auto t1 = (aabb.min.z - origin.z)/direction.z;
            auto t2 = (aabb.max.z - origin.z)/direction.z;
            
            tmin = max(tmin, min(t1, t2));
            tmax = min(tmax, max(t1, t2));
        }

        distance = tmin;
        return tmax >= tmin && tmax >= 0;
    }

    unittest
    {
        ray r = ray(vec3(0,0,0), vec3(1,0.0001,0.0001));
        float distance;

        assert(r.intersects(AABB(vec3(-1,-1,-1), vec3(-0.5f,-0.5f,-0.5f)), distance) == false);
        assert(r.intersects(AABB(vec3(10,10,10), vec3(100,100,100)), distance) == false);
        assert(r.intersects(AABB(vec3(0.5f,-1,-1), vec3(1,1,1)), distance) == true);
        assert(r.intersects(AABB(vec3(1000.5f,-10,-1), vec3(1,1,1)), distance) == true);
    }
}

alias Ray!(float) ray;