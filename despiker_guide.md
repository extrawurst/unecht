# despiker guide

* use my fork of [despiker](https://github.com/Extrawurst/despiker)
* download SDL2 lib for your platform and place it in system folders
* build despiker using `dub build`
* copy despiker binary right beside your ue-engine/game binary so that it finds it
* test if it works by starting despiker alone in a dry run using `$ ./despiker` and see a window like below
* if that all works attach "UEProfiling" to your ue-engine project, rebuild and press `cmd+shift+p` in the app to popup profiler window

![despiker alone](https://raw.github.com/extrawurst/unecht/master/screenshots/2015-03-28-despiker.png)

more info on despiker and the underlying frame profiler is here: [link](http://defenestrate.eu/docs/despiker/tutorials/getting_started.html)
