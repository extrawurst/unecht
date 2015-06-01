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

protected:
    int _width;
    int _height;
}

///
final class UETexture2D : UETexture
{
    import derelict.freeimage.freeimage;

    mixin(UERegisterObject!());

    ///
    this()
    {
        super(1,1);
    }

    ///
    void loadFromFile(string path)
    {
        FIMEMORY* stream;
        stream = FreeImage_OpenMemory(cast(ubyte*)path.ptr, path.length);
        assert(stream);
        scope(exit) FreeImage_CloseMemory(stream);

        auto ftype = FreeImage_GetFileTypeFromMemory(stream, cast(int)path.length);
        
        FIBITMAP* bitmap = FreeImage_LoadFromMemory(ftype, stream);
        scope(exit) FreeImage_Unload(bitmap);
        
        createRaw(bitmap);
    }

    private void createRaw(FIBITMAP* _image)
    {
        //TODO: check if bits are not 32 first
        FIBITMAP* pImage = FreeImage_ConvertTo32Bits(_image);
        scope(exit) FreeImage_Unload(pImage);
        _width = FreeImage_GetWidth(pImage);
        _height = FreeImage_GetHeight(pImage);
        /+
        glGenTextures(1, &tex);
        
        glBindTexture(GL_TEXTURE_2D, tex);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, _width, _height,
            0, GL_BGRA, GL_UNSIGNED_BYTE, cast(void*)FreeImage_GetBits(pImage));
            +/
    }
}

///
final class UETextureCubemap : UETexture
{
    mixin(UERegisterObject!());

    this(int size)
    {
        super(size,size);
    }

private:
    @Serialize
    UETexture2D[6] faces;
}
