'' Play music and SFX '''''''''''''''''''''''''''''''''''''''''''''''''''''''''

#define sound_disabled_str arg(0) & " - Audio was disabled at compiletime."

#ifdef _SND_SUPPORT_
#include "SDL2/SDL_mixer.bi"

'' Initialise SDL Mixer
Mix_OpenAudio( 44100, MIX_DEFAULT_FORMAT, 2, 4096 )
Mix_VolumeMusic(128)

#endif

'' Wrapper for playing sounds as text is printed in dialogue boxes
Sub DialogueSound( ByVal filename As String = "", ByVal dontJustLoad As Boolean = true )
	#ifdef _SND_SUPPORT_
	Static As String	sfx_file
	Static As Mix_chunk Ptr	sfx
	
	'' Load a new file if one is specified
	If (filename <> "") and (filename <> sfx_file) Then
		If sfx <> 0 Then
			Mix_FreeChunk(sfx)
		Endif
		
		sfx = Mix_LoadWav(filename)
		
		sfx_file = filename
	Endif
	
	'' Allows loading new sample without playing one
	If dontJustLoad Then
		Mix_PlayChannel(-1,sfx,0)
	Endif
	#endif
End Sub

