module unecht.core.application;

import unecht.core.types;
import unecht.core.window;

/// application base interface
interface UEApplication
{
    /// root entry - gets called by main function and blocks until end of application
    int run();
    ///
    void terminate();
    ///
    void openProfiler();
    ///
    void openSteamOverlay();
    ///
    UESize windowSize();
    ///
    UESize framebufferSize();
    ///
    UEWindow mainWindow();
}