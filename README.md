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

Everything seems to build with the 64bit version of windows with no need for additional dependancies, although I need to check that out more thoroughly later.

FreeBASIC can be obtained at [FreeBASIC.net](https://freebasic.net/)


