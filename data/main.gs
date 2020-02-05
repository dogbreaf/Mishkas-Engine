// Load the player graphcis
Player Sprite "data/sprite/player.bmp" 192 24 3
Player SimpleCollision

TextSpeed 20

Font "data/slim_font.bmp"

:Start
Splash "data/mainmenu.bmp"
Option Add MMLoad "Continue"
Option Add NewGame "New Game"
Option Add EndOfGame "Quit"
Option Select

Quit

:NewGame

// test the inventory function
Inventory Add UseMedkit "MedKit" 10 "A first aid kit."
Inventory Add UseBullet "Bullets" 20 "Bullets for a pistol."
Inventory Add UsePistol "Pistol" 1 "A small pistol." true

// Play music test
PlayMusic "data/audio/USL_LOOP.mp3"

// Load the main area
Goto LoadMap

// Start the game
:Main
RunGame

:MainMenu
Option Add MMInv "Inventory"
Option Add MMSave "Save"
Option Add MMLoad "Load"
Option Add MMQuit "Quit"
Option Add Main "Cancel"

Option Select
Goto Main

:MMQuit
Quit

:MMInv
Set ReturnLabel = MMInv
Inventory Show
Set ReturnLabel = ""
Goto Main

:MMSave
Set saved = true
Dialouge "Saving..." false
SaveStack "data/game.sav"
Inventory Save "data/inventory.sav"
Set saved = false
Sleep 1000
Dialouge "Saved."
Goto Main

:MMLoad
// Load the Save
LoadStack "data/game.sav"
Inventory Load "data/inventory.sav"
If %saved% = true
	Player Position %_PlayerX% %_PlayerY%

	Dialouge "Loaded saved data. (%_PlayerX% %_PlayerY% in %PreviousLocation%)"

	Set LoadGame = true
	Goto %PreviousLocation%
Endif
Dialouge "Save data was not found or was corrupt."
Goto Start

// Utility scripts
Include "data/script/items.gs"
// All the stuff for different areas
Include "data/script/map.gs"
Include "data/script/pharmacy.gs"
Include "data/script/shop.gs"

