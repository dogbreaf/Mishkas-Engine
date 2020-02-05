'' Play music and SFX '''''''''''''''''''''''''''''''''''''''''''''''''''''''''

#define sound_disabled_str arg(0) & " - Audio was disabled at compiletime."

#ifdef _SND_SUPPORT_
#include "SDL2/SDL_mixer.bi"

'' Initialise SDL Mixer
Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 4096 )
Mix_VolumeMusic(128)

#endif

