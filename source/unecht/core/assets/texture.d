module unecht.core.assets.texture;

import unecht.core.component;
import unecht.core.object;
import unecht.core.serialization.serializer;
import unecht.core.defaultInspector;

///
enum UETextureFiltering
{
    point,
    linear,
    trilinear
}

///
enum UETextureRepeat
{
    clamp,
    repeat
}

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

    ///
    @property UETextureFiltering filter() const { return _filtering; }
    ///
    @property UETextureRepeat repeat() const { return _repeat; }
    ///
    @property void filter(UETextureFiltering v) { _filtering = v; }
    ///
    @property void repeat(UETextureRepeat v) { _repeat = v; }

//TODO: make privte again once defaultInspector can edit private fields
//protected:
    @Serialize
    UETextureFiltering _filtering;
    @Serialize
    UETextureRepeat _repeat;

    int _width;
    int _height;
}

///
@UEDefaultInspector!UETexture2D
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
        import std.string:toStringz;
        auto fn = toStringz(path);
        
        FIBITMAP* bitmap = FreeImage_Load(FreeImage_GetFileType(fn, 0), fn);
        scope(exit) FreeImage_Unload(bitmap);
        createRaw(bitmap);
    }

    private void createRaw(FIBITMAP* _image)
    {
        //TODO: check if bits are not 32 first
        FIBITMAP* pImage = FreeImage_ConvertTo32Bits(_image);
        scope(exit) FreeImage_Unload(pImage);
        _width = FreeImage_GetWidth(_image);
        _height = FreeImage_GetHeight(_image);

        import std.stdio;
        writefln("tex created: %sx%s",_width,_height);
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
