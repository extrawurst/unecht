module unecht.core.assets.texture;

import unecht.core.component;
import unecht.core.object;
import unecht.core.serialization.serializer;
import unecht.core.defaultInspector;

import derelict.opengl3.gl3;

///
enum UETextureFiltering
{
    point,
    linear,
}

///
enum UETextureRepeat
{
    clamp,
    repeat
}

///
abstract class UETexture : UEObject
{
    mixin(UERegisterObject!());

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
    ///
    @property bool isValid() const { return _glTex != 0; }
    ///
    @property void* driverHandle() const { return cast(void*)_glTex; }

    void bind()
    {
        glBindTexture(GL_TEXTURE_2D, _glTex);

        auto glFiltering = GL_NEAREST;
        if(_filtering == UETextureFiltering.linear)
            glFiltering = GL_LINEAR;

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, glFiltering);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, glFiltering);

        auto glClamp = GL_CLAMP_TO_EDGE;
        if(_repeat == UETextureRepeat.repeat)
            glClamp = GL_REPEAT;        

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }

    void unbind()
    {
        glBindTexture(GL_TEXTURE_2D, 0);
    }

protected:
    @Serialize
    UETextureFiltering _filtering;
    @Serialize
    UETextureRepeat _repeat;

    int _width;
    int _height;

    GLuint _glTex;
}

///
final class UETexture2D : UETexture
{
    import derelict.freeimage.freeimage;

    mixin(UERegisterObject!());

    ///
    public void loadFromFile(string path)
    {
        import std.string:toStringz;
        import std.file:exists;

        auto fn = toStringz(path);

        assert(exists(path));
        
        FIBITMAP* bitmap = FreeImage_Load(FreeImage_GetFileType(fn, 0), fn);
        scope(exit) FreeImage_Unload(bitmap);

        createRaw(bitmap);
    }

    ///
    public void loadFromMemFile(ubyte[] mem)
    {
        auto memHandle = FreeImage_OpenMemory(mem.ptr, mem.length);
        assert(memHandle);
        scope(exit) FreeImage_CloseMemory(memHandle);

        auto format = FreeImage_GetFileTypeFromMemory(memHandle, cast(int)mem.length);
        import unecht.core.logger;
        import std.conv;
        log.logf("loadFromMemFile: %s",to!string(format));

        FIBITMAP* bitmap = FreeImage_LoadFromMemory(format, memHandle);
        assert(bitmap);
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

        assert(pImage !is null);
        assert(FreeImage_GetBPP(pImage) == 32);
        
        glGenTextures(1, &_glTex);
        
        glBindTexture(GL_TEXTURE_2D, _glTex);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, _width, _height,
            0, GL_BGRA, GL_UNSIGNED_BYTE, cast(void*)FreeImage_GetBits(pImage));
    }
}
/+
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
+/