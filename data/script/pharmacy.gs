Goto End_Pharmacy
:LoadPharmacy
If %LoadGame% != true
	StopMusic
	PlaySFX "data/audio/transition_tmp.wav"
	Transition FADE
	Sleep 350
Endif

LoadTileSet "data/tileset/tileset.bmp"
LoadTileMap "data/map/pharmacy.dat"

If %LoadGame% != true
	Player Position 34 23
Endif
Set LoadGame = false

// Set this to the label of this map so that we can load it with a save
Set PreviousLocation = LoadPharmacy

// Clear old objects
Object Clear

// Add triggers
// main entrance/exit
Trigger 33 22 LoadMap
Trigger 34 22 LoadMap

// Shelves
Trigger 25 26 Pharmacy_Shelves
Trigger 26 26 Pharmacy_Shelves
Trigger 25 27 Pharmacy_Shelves
Trigger 26 27 Pharmacy_Shelves

Trigger 29 26 Pharmacy_Shelves
Trigger 29 27 Pharmacy_Shelves

// Cash register
Trigger 34 28 Pharmacy_CashRegister
Trigger 35 28 Pharmacy_CashRegister

// PC
Trigger 28 36 Pharmacy_Terminal
Trigger 29 36 Pharmacy_Terminal

PlayMusic "data/audio/sleepy_cave.mp3"

Goto Main

:Pharmacy_CashRegister
Dialouge "You check the cash register for goodies..."
If %LOOTED.PharmacyCashRegister% != true
	Dialouge "You found some old money\c19"
	Set LOOTED.PharmacyCashRegister = true
	
	Inventory Add UseOldMoney "Money" 10 "Old money, its not worth anything now..."
	
	Goto Main
Endif
If %LOOTED.PharmacyCashRegister% = true
	Dialouge "It was empty..."
Endif
Goto Main

:Pharmacy_Shelves
Random LootChance 0 100
If %LootChance% < 4 
	Dialouge "You found some painkillers on the shelves, nice \c19 "
	
	Inventory Add UsePainkiller "Painkiller" 1 "These might be out of date, but they might still help..."
	Goto Main
Endif
Dialouge "The shelves are bare..."
Goto Main

:Pharmacy_Terminal
Dialouge "This terminal is broken, it wont help."
Goto Main

// End of Auto-generated template
:End_MainMap

