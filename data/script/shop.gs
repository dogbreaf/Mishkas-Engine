Goto EndShop
:LoadShop
If %LoadGame% != true
	StopMusic
	PlaySFX "data/audio/transition_tmp.wav"
	Transition FADE
	Sleep 350
Endif

LoadTileSet "data/tileset/tileset.bmp"
LoadTileMap "data/map/shop.dat"

If %LoadGame% != true
	Player Position 31 13
Endif
Set LoadGame = false

// Set this to the label of this map so that we can load it with a save
Set PreviousLocation = LoadShop

// Clear old objects
Object Clear

// Add triggers
Trigger 30 12 LoadMap
Trigger 31 12 LoadMap

Trigger 30 18 Shop_CashRegister
Trigger 31 18 Shop_CashRegister

Trigger 24 17 Shop_Shelves
Trigger 24 18 Shop_Shelves

Trigger 27 17 Shop_Shelves
Trigger 27 18 Shop_Shelves

PlayMusic "data/audio/sleepy_cave.mp3"

Goto Main

:Shop_CashRegister
Dialouge "You check the cash register for goodies..."
If %LOOTED.ShopCashRegister% != true
	Dialouge "You found some old money\c19"
	Set LOOTED.ShopCashRegister = true
	Random LootAmount 1 15
	
	Inventory Add UseOldMoney "Money" %LootAmount% "Old money, its not worth anything now..."
	
	Goto Main
Endif
If %LOOTED.ShopCashRegister% = true
	Dialouge "It was empty..."
Endif
Goto Main

:Shop_Shelves
Random LootChance 0 100
If %LootChance% < 7
	Dialouge "You found some chocolate on the shelves, nice \c19 "
	
	Inventory Add UseChocolate "Chocolate" 1 "Super high calorie goodness."
	Goto Main
Endif
Dialouge "The shelves are bare..."
Goto Main

:EndShop

