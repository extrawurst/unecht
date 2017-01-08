# scod - documentation generator
[![Build Status](https://travis-ci.org/MartinNowak/scod.svg?branch=master)](https://travis-ci.org/MartinNowak/scod) [![Dub](https://img.shields.io/dub/v/scod.svg)](http://code.dlang.org/packages/scod)

Scod is a clean and lightweight theme for [ddox](https://github.com/rejectedsoftware/ddox),
simply use It as drop-in replacement.

[Newer dub versions](https://github.com/dlang/dub/blob/f7b4db4790c4ee96bb8a77869e521acb0072357b/CHANGELOG.md#v0925---2016-05-22) (>=0.9.25) have a switch to configure the ddox tool.
The following configuration tells dub to use scod for documentation generation with `dub build --build=ddox`.

- `x:ddoxTool "scod"` (dub.sdl)
- `  "-ddoxTool": "scod"` (dub.json)

![Example](scod.png)
