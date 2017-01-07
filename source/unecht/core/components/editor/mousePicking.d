module unecht.core.components.editor.mousePicking;

version(UEIncludeEditor):

import unecht.ue;
import unecht.core.entity;
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
        auto renderers = ue.scene.gatherAllComponents!UERenderer;

        UEEntity target;
        float minDistance = float.infinity;

        foreach(r; renderers)
        {
            if(r.enabled && r.sceneNode.enabled && r.sceneNode.parent.enabled && r.entity.layer != UELayer.editor)
            {
                auto box = r.mesh.aabb.scale(r.sceneNode.scaling);
                box = box.translate(r.sceneNode.position);

                float distance;
                if(_r.intersects(box,distance))
                {
                    if(!target || minDistance > distance)
                    {
                        target = r.entity;
                        minDistance = distance;
                    }
                }
            }
        }

        import unecht.core.components._editor;
        EditorRootComponent.selectEntity(target);
    }
}

static AABB scale(AABB box, vec3 scaling)
{
    return AABB(box.min.scale(scaling), box.max.scale(scaling));
}

static vec3 scale(vec3 a, vec3 b)
{
    return vec3(a.x * b.x, a.y * b.y, a.z * b.z);
}

static AABB translate(AABB box, vec3 translate)
{
    return AABB(box.min + translate, box.max + translate);
}
