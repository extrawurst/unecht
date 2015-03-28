# despiker guide

* use my fork of [despiker](https://github.com/Extrawurst/despiker)
* download SDL2 lib for your platform and place it in system folders
* build despike using `dub build` (see [dub](https://github.com/D-Programming-Language/dub) for further info)
* copy despiker binary right beside your ue-engine/game binary so it finds it
* test if it works by starting despiker alone in a dry run using `$ ./despiker` and see a window like below
* if that all works attach "UEProfiling" to your ue-engine project, rebuild and press `cmd+shift+p` in the app to popup profiler window

![despiker alone](https://raw.github.com/extrawurst/unecht/master/screenshots/2015-03-28 despiker.png)
