module unecht.core.math.ray;

import gl3n.linalg;
import gl3n.aabb;

///
struct Ray(T)
{
    alias Vector!(T,3) VecType;
    VecType  origin = VecType(0,0,0);
    VecType  direction = VecType(0,0,0);

    ///
    public @nogc bool intersects(AABBT!T aabb, ref float min)
    {
        import std.math:abs;

        min = 0.0f; // set to -FLT_MAX to get first hit on line
        float tmax = float.infinity;// set to max distance ray can travel (for segment)

        auto p = origin.vector;
        auto d = direction.vector;
        alias a = aabb;

        // For all three slabs
        for (int i = 0; i < 3; i++) {
            if (abs(d[i]) < float.epsilon) {
                // Ray is parallel to slab. No hit if origin not within slab
                if (p[i] < a.min.vector[i] || p[i] > a.max.vector[i]) return false;
            } else {
                // Compute intersection t value of ray with near and far plane of slab
                float ood = 1.0f / d[i];
                float t1 = (a.min.vector[i] - p[i]) * ood;
                float t2 = (a.max.vector[i] - p[i]) * ood;
                // Make t1 be intersection with near plane, t2 with far plane
                if (t1 > t2) swap(t1, t2);
                // Compute the intersection of slab intersection intervals
                if (t1 > min) min = t1;
                if (t2 > tmax) tmax = t2;
                // Exit with no collision as soon as slab intersection becomes empty
                if (min > tmax) return false;
            }
        }

        return true;
    }

    unittest
    {
        ray r = ray(vec3(0,0,0), vec3(1,0,0));
        float distance;

        assert(r.intersects(AABB(vec3(-1,-1,-1), vec3(-0.5f,-0.5f,-0.5f)), distance) == false);
        assert(r.intersects(AABB(vec3(0.5f,-1,-1), vec3(1,1,1)), distance) == true);
        assert(r.intersects(AABB(vec3(1000.5f,-10,-1), vec3(1,1,1)), distance) == true);
    }

    private static void swap(T)(ref T a, ref T b)
    {
        auto tmp = a;
        a = b;
        b = tmp;
    }
}

alias Ray!(float) ray;