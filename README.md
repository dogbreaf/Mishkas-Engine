# Mishkas Engine

![alt-text](https://github.com/dogbreaf/Mishkas-Engine/blob/experemental/other%20assets/screenshot.jpg?raw=true "Screenshot of the game")

This project is in a very unfinished state (Although if the code happens to be functional at any given moment I think there is enough functionality to maybe do something actually interesting).

Obviously there are much better game engines for this purpose but I wanted to make my own, just to enjoy the challenges and process even if doing so isnt super worth-while.

This is one of the biggest most complicated projects I have worked on and includes some old code of mine, so some of it is probably not very good or
doesn't make sense but my main concern at this point is not go get bogged down in the details and just try to keep things relatively simple and fast.

## Build instructions
To build the project on windows or linux, just pass the main source file to
fbc, e.g.:
```bash
$ fbc game.bas
$ fbc edit2.bas
```

On linux you will need to install some dev packages if you do not normally use freebasic. I will include a list of what those are at some point. Additionally you will also need your distro's equivalent of `libsdl2-dev` and `libsdl2-mixer-dev` for sound, otherwise remove `#define _SND_SUPPORT_` from the top of game.bas to completely disable audio.

On windows if Image support is enabled you must add FreeImage.lib and FreeImage.dll to the root folder of the project. For sound support you will need SDL2.lib, SDL2.dll, SDL2_Mixer.lib, SDL2_Mixer.dll and any additional codec DLLs your project needs. Once built only the DLL files are required.

To disable the console on windows pass `-s gui` to the compiler.

FreeBASIC can be obtained at [FreeBASIC.net](https://freebasic.net/)

##  Licenses
This project uses [SDL Mixer](https://www.libsdl.org/license.php), which is licensed under the zlib license as part of SDL2.
It also uses [FreeImage](http://freeimage.sourceforge.net/license.html), which is provided under the GNU GPL v3.

The project it's self is under the GNU GPL v3.
