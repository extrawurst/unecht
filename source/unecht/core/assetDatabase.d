module unecht.core.assetDatabase;

import unecht.core.object;
import unecht.core.serialization.serializer;

///
struct UEAsset
{
    UEObject obj;
    string path;
}

///
static struct UEAssetDatabase
{
    static UEAsset[] assets;

    static immutable EXT_METAFILE = ".uem";

    ///
    static void refresh()
    {
        import std.path:dirName;
        import std.file:thisExePath;

        auto binaryPath = dirName(thisExePath());

        refresh(binaryPath ~ "/assets/");
    }

    ///
    static void refresh(string path)
    {
        import std.file:DirEntry,dirEntries,SpanMode;
        import std.path:relativePath;

        foreach (DirEntry e; dirEntries(path, SpanMode.breadth))
        {
            auto relPath = relativePath(e.name, path);

            if(!containsPath(relPath))
            {
                parseAssetFile(relPath);
            }
        }
    }

    ///
    static bool containsPath(string path)
    {
        import std.algorithm;
        return countUntil!"a.path == b"(assets,path) != -1;
    }

    ///
    static void parseAssetFile(string path)
    {
        import std.path:extension;

        import std.stdio;
        writefln("parse: '%s'",path);

        auto ext = extension(path);

        //TODO: solve different extension using a dictonary of assetimporters
        if(ext == ".png")
        {
            loadTextureAsset(path);
        }
    }

    ///
    static void loadTextureAsset(string path)
    {
        import std.path:exists;
        import unecht.core.assets.texture;

        UETexture2D tex;
      
        if(exists(path ~ EXT_METAFILE))
        {
            tex = deserializeMetaFile!UETexture2D(path ~ EXT_METAFILE);
        }
        else
        {
            tex = new UETexture2D();
            serializeMetaFile(tex, path);
        }

        tex.loadFromFile(path);

        addAsset(tex, path);
    }

    ///
    static void addAsset(UEObject obj, string path)
    {
        assets ~= UEAsset(obj, path);
    }

    ///
    private static void serializeMetaFile(UEObject obj, string path)
    {
        import std.file;

        UESerializer s;
        obj.serialize(s);
        write(path, s.toString());
    }

    ///
    private static auto deserializeMetaFile(T)(string path)
    {
        import std.file;
        string fileContent = cast(string)read(path);

        UEDeserializer d = UEDeserializer(fileContent);
        return d.deserializeFirst!T();
    }
}