unecht [![Stories in Ready](https://badge.waffle.io/Extrawurst/unecht.png?label=ready&title=Ready)](https://waffle.io/Extrawurst/unecht) [![Build Status](https://travis-ci.org/Extrawurst/unecht.svg)](https://travis-ci.org/Extrawurst/unecht)
===

Game Engine Framework written in #dlang

![menus](https://raw.github.com/extrawurst/unecht/master/screenshots/2015-05-27 menus.gif)
![editor inspectors](https://raw.github.com/extrawurst/unecht/master/screenshots/2015-04-15 editorInspectors.png)
![openassimp](https://raw.github.com/extrawurst/unecht/master/screenshots/2015-05-01.png)
![enet based networking](https://raw.github.com/extrawurst/unecht/master/screenshots/2015-05-02 enet chat.png)

# features

* editor mode to inspect scene at runtime
* component based design (think [unity3d](http://unity3d.com/))
* integrated physics engine ([ODE](http://ode-wiki.org))

# dependecies

* opengl 3.3 (core profile) compatible graphics/drivers
* glfw library ([link](http://www.glfw.org/))
* ODE physics library ([link](http://ode-wiki.org/wiki/index.php?title=Manual:_Install_and_Use))
* freeimage library ([link](http://freeimage.sourceforge.net/))
* frame profiling: despiker binary right besides engine binary ([guide](despiker_guide.md))
* cimgui library ([link](https://github.com/Extrawurst/cimgui))
* steamworks library ([link](https://github.com/Extrawurst/DerelitSteamworks)) (optionally enabled using `EnableSteam` version)
* openassimp library ([link](http://assimp.sourceforge.net/)) (just in a sample for now)
* fmod library ([link](http://www.fmod.org/download/#StudioAPI)) (just in a sample for now)
* enet library ([link](http://enet.bespin.org/)) (just in a sample for now)
