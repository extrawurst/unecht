module unecht.core.window;

import unecht.core.types;

///
interface UEWindow
{
    ///
    bool isCursorPosInside(float x, float y) pure const;
    ///
    public @property bool isRetina() const;
    ///
    @property bool shouldClose();
    ///
    @property UESize windowSize() const;
    ///
    @property UESize framebufferSize() const;
    ///
    void wrapAroundCursorPos(float x, float y);
    ///
    void* windowPtr();
}