Goto End_MainMap
:LoadMap
If %LoadGame% != true
	StopMusic
	PlaySFX "data/audio/transition_tmp.wav"
	Transition FADE
	Sleep 350
Endif
:LoadMap_SkipTransition

LoadTileSet "data/tileset/tileset.bmp"
LoadTileMap "data/map/map.dat"

If %LoadGame% != true
	Player Position 42 1
Endif
Set LoadGame = false

// Check previous locations
If %PreviousLocation% = LoadPharmacy
	Player Position 22 25
Endif
If %PreviousLocation% = LoadShop
	Player Position 51 10
Endif

// Set this to the label of this map so that we can load it with a save
Set PreviousLocation = LoadMap

// Clear old objects
Object Clear

// Add triggers
// Road to factory
For i 39 46
	Trigger %i% 0 Map_FactoryRoad
Next

// Sign post
Trigger 38 14 Map_Sign
Trigger 39 14 Map_Sign
Trigger 38 15 Map_Sign
Trigger 39 15 Map_Sign

// Fallout shelter
Trigger 47 44 Map_FalloutShelter
Trigger 48 44 Map_FalloutShelter

// Pharmacy (Should be LoadParmacy, but it doesnt exist yet)
Trigger 21 24 LoadPharmacy
Trigger 22 24 LoadPharmacy

// Shop (Should be LoadShop)
Trigger 50 9 LoadShop
Trigger 51 9 LoadShop

// Flats
Trigger 53 27 Map_Flats
Trigger 54 27 Map_Flats

//
Trigger 28 24 Map_Mark
Trigger 29 24 Map_Mark

// Finally set the music
// Play music test
PlayMusic "data/audio/USL_LOOP.mp3"

Goto Main

// Trigger code segments
:Map_Sign
Dialouge "\c24  Factory\n\c25  Village"
Set Map_ReadSign = true
Goto Main

:Map_FactoryRoad
If %Map_ReadSign% != true
	Dialouge "It's not time to go there yet."
Endif
If %Map_ReadSign% = true
	Dialouge "It's not time to go to the factory yet."
Endif

Set _PlayerY += 1
Player Position %_PlayerX% %_PlayerY%
Goto Main

:Map_FalloutShelter
Dialouge "The fallout shelter is locked."
Set _PlayerY += 1
Player Position %_PlayerX% %_PlayerY%
Goto Main

:Map_Mark
Dialouge "Whew that lamp post... you should scent mark it..."
Confirm Map_Mark2 "Pee on the lamp post?"
Goto Main
:Map_Mark2
Dialouge "..."
Dialouge "You peed on the lamp post\c19  \c2"
Goto Main

:Map_Flats
Dialouge "The door is blocked, there must be something behind it..."
Set _PlayerY += 1
Player Position %_PlayerX% %_PlayerY%
Goto Main

// End of Auto-generated template
:End_MainMap
