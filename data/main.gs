// Load the player graphcis
Player Sprite "data/sprite/player.bmp" 192 24 3
Player SimpleCollision

TextSpeed 20

// test the inventory function
Inventory Add UseMedkit "First Aid Kit" 10 "A first aid kit."
Inventory Add UseBullet "Bullets" 100 "Bullets for a pistol."
Inventory Add UsePistol "Pistol" 1 "A small pistol." true

For i 0 100
	Random Q 10 100
	Inventory Add UseMisc "Misc Item %i%" %Q% "A misculaneous item labelled %i%"
Next

// Dummy attack routine
//ActionTrigger Attack

// Load the main area
Goto LoadTemplate

// Start the game
:Main
RunGame

:MainMenu
Option Add MMInv "Inventory"
Option Add MMSave "Save"
Option Add MMLoad "Load"
Option Add MMQuit "Quit"
Option Add MMLighting "Edit Lighting"
Option Add DumpCode "Dump code file"
Option Add Main "Cancel"

Option Select
Goto Main

:MMQuit
Quit

:MMInv
Inventory Show
Goto Main

:MMSave
Dialouge "Saving..." false
SaveStack "data/game.sav"
Inventory Save "data/inventory.sav"
Sleep 1000
Dialouge "Saved."
Goto Main

:MMLoad
// Load the Save
LoadStack "data/game.sav"
Inventory Load "data/inventory.sav"
If %__PlayerX% > 0
	Player Position %_PlayerX% %_PlayerY%

	Dialouge "Loaded saved data. (%_PlayerX% %_PlayerY%)"
Endif
Goto Main

:MMLighting
Dialouge "Select lighting mode..." false
Option Add FX_CLEAR "Clear"
Option Add FX_INTEGRATED "Integrated"
Option Add FX_IMAGE "Image file"
Option Select
Goto MainMenu

:FX_CLEAR
Light Delete
Dialouge "Cleared lighting effect."
Goto Main

:FX_INTEGRATED
Light Radius 64
Dialouge "Set 64 pixel radius circle."
Goto Main

:FX_IMAGE
Light Set "data/playerlight.bmp" 128 128
Dialouge "Set as data/playerlight.bmp"
Goto Main

:DumpCode
Dump "main.dump.gs"
Dialouge "Code dumped to main.dump.gs"
Goto Main

//
:Attack
Dialouge "You have no weapon."
Goto Main

// All the stuff for different areas
Include "data/script/map.gs"

