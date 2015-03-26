module unecht.gl.texture;

import derelict.freeimage.freeimage;
import derelict.opengl3.gl3;

final class GLTexture
{
	GLuint tex;

	bool pointFiltering=false;

	void create(string _file, bool _fromMemory=true)
	{
		if(!_fromMemory)
		{
			import std.string;
			auto fn = toStringz(_file);

			FIBITMAP* bitmap = FreeImage_Load(FreeImage_GetFileType(fn, 0), fn);
			scope(exit) FreeImage_Unload(bitmap);
			createRaw(bitmap);
		}
		else
		{
			FIMEMORY* stream;
			stream = FreeImage_OpenMemory(cast(ubyte*)_file.ptr, _file.length);
			assert(stream);
			scope(exit) FreeImage_CloseMemory(stream);

			auto ftype = FreeImage_GetFileTypeFromMemory(stream, cast(int)_file.length);

			FIBITMAP* bitmap = FreeImage_LoadFromMemory(ftype, stream);
			scope(exit) FreeImage_Unload(bitmap);

			createRaw(bitmap);
		}
	}

	private void createRaw(FIBITMAP* _image)
	{
		//TODO: check if bits are not 32 first
		FIBITMAP* pImage = FreeImage_ConvertTo32Bits(_image);
		scope(exit) FreeImage_Unload(pImage);
		auto nWidth = FreeImage_GetWidth(pImage);
		auto nHeight = FreeImage_GetHeight(pImage);
		
		glGenTextures(1, &tex);
		
		glBindTexture(GL_TEXTURE_2D, tex);
		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, nWidth, nHeight,
			0, GL_BGRA, GL_UNSIGNED_BYTE, cast(void*)FreeImage_GetBits(pImage));
	}

	void bind()
	{
		glBindTexture(GL_TEXTURE_2D, tex);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, pointFiltering?GL_NEAREST:GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, pointFiltering?GL_NEAREST:GL_LINEAR);
        //TODO: parameterize
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	}

	void unbind()
	{
		glBindTexture(GL_TEXTURE_2D, 0);
	}
}