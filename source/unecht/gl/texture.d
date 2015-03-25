module unecht.gl.texture;

import derelict.freeimage.freeimage;
import derelict.opengl3.gl3;

final class GLTexture
{
	GLuint tex;

	void create(string _file)
	{
		import std.string;
		auto fn = toStringz(_file);

		FIBITMAP* bitmap = FreeImage_Load(FreeImage_GetFileType(fn, 0), fn);
		scope(exit) FreeImage_Unload(bitmap);

		FIBITMAP* pImage = FreeImage_ConvertTo32Bits(bitmap);
		scope(exit) FreeImage_Unload(pImage);
		auto nWidth = FreeImage_GetWidth(pImage);
		auto nHeight = FreeImage_GetHeight(pImage);

		glGenTextures(1, &tex);
		
		glBindTexture(GL_TEXTURE_2D, tex);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);


		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, nWidth, nHeight,
			0, GL_BGRA, GL_UNSIGNED_BYTE, cast(void*)FreeImage_GetBits(pImage));

	}

	void bind()
	{
		glBindTexture(GL_TEXTURE_2D, tex);
	}

	void unbind()
	{
		glBindTexture(GL_TEXTURE_2D, 0);
	}
}