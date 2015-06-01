module unecht.core.assets.texture;

import unecht.core.component;
import unecht.core.object;
import unecht.core.serialization.serializer;

///
class UETexture : UEObject
{
    mixin(UERegisterObject!());

    ///
    private this(int width, int height)
    {
        _width = width;
        _height = height;
    }

    ///
    @property int width() const { return _width; }
    ///
    @property int height() const { return _height; }

private:
    int _width;
    int _height;
}

///
final class UETextur2D : UETexture
{
    mixin(UERegisterObject!());

    this(int width, int height)
    {
        super(width,height);
    }
}

///
final class UETexturCubemap : UETexture
{
    mixin(UERegisterObject!());

    this(int size)
    {
        super(size,size);
    }

private:
    @Serialize
    UETextur2D[6] faces;
}
