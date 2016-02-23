module unecht.core.components.editor.mousePicking;

//version(UEIncludeEditor):

import unecht;
import unecht.core.components.renderer;
import unecht.core.math.ray;

import unecht.core.stdex;

import gl3n.linalg;
import gl3n.aabb;

///
struct MousePicking
{
    ///
    public static void onPick(ray _r)
    {
        import unecht.core.logger;
        log.logf("pick: %s",_r.direction);

        auto renderers = ue.scene.gatherAllComponents!UERenderer;

        UEEntity target;
        float minDistance = float.infinity;

        foreach(r; renderers)
        {
            if(r.enabled && r.sceneNode.enabled && r.sceneNode.parent.enabled && r.entity.layer != UELayer.editor)
            {
                auto pos = r.entity.sceneNode.position;
                auto box = AABB(r.mesh.aabb.min + pos, r.mesh.aabb.max + pos);

                float distance;
                if(_r.intersects(box,distance))
                {
                    import unecht.core.logger;
                    log.logf("hit: %s (%s)", r.entity.name, distance);

                    if(!target || (target && minDistance > distance))
                    {
                        target = r.entity;
                        minDistance = distance;
                    }
                }
            }
        }

        if(target)
        {
            import unecht.core.logger;
            log.logf("picked: %s (%s)", target.name, minDistance);
        }
    }
}
