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
    static immutable ASSETFOLDER = "/assets/";

    private static string assetPath() { 
        import std.path:dirName;
        import std.file:thisExePath;

        return dirName(thisExePath()) ~ ASSETFOLDER; 
    }

    ///
    static void refresh()
    {
        refresh(assetPath());
    }

    ///
    static void refresh(string path)
    {
        import std.file:DirEntry,dirEntries,SpanMode;
        import std.path:relativePath,exists;

        if(!exists(path))
            return;

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

        auto ext = extension(path);

        import unecht.core.logger;
        log.infof("parse: '%s' (%s)",path, ext);

        //TODO: solve different extension using a dictonary of assetimporters
        if(ext == ".png")
        {
            loadTextureAsset(path);
        }
    }

    ///
    static void loadTextureAsset(string path)
    {
        import std.file:exists;
        import unecht.core.assets.texture;

        UETexture2D tex;
        immutable assetFile = assetPath ~ path;
        immutable metaFilePath = assetFile ~ EXT_METAFILE;
      
        if(exists(metaFilePath))
        {
            tex = deserializeMetaFile!UETexture2D(metaFilePath);
        }
        else
        {
            tex = new UETexture2D();
            serializeMetaFile(tex, metaFilePath);
        }

        tex.loadFromFile(assetFile);

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

        auto serializedStr = s.toString();

        write(path, serializedStr);

        import unecht.core.logger;
        log.infof("written uem: (%s) -> \n%s",path,serializedStr);
    }

    ///
    private static auto deserializeMetaFile(T)(string path)
    {
        import std.file;
        string fileContent = cast(string)read(path);

        import unecht.core.logger;
        log.infof("uem read: (%s)",path);

        UEDeserializer d = UEDeserializer(fileContent);
        return d.deserializeFirst!T();
    }
}