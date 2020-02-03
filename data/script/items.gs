// Don't run anything here if execution strays this low
Goto EndItemsGS

:UseMedkit
Dialogue "You don't need to use a medkit now..."
Goto ReturnToLabel

:UseBullet
Dialouge "There is a time and a place for everying..."
Goto ReturnToLabel

:UsePistol
Dialouge "There is a time and a place for everything..."
Goto ReturnToLabel

:UsePainkiller
Inventory Rem "Painkiller" 1
Dialouge "You dry swallow the pills, they are aweful and you aren't\nsure they did anything."
Goto ReturnToLabel

:UseOldMoney
Dialouge "This shit is worthless..."
Goto ReturnToLabel

:UseChocolate
Inventory Rem "Chocolate" 1
Dialouge "The chocolate is old and has bloom, but it still tastes good."
Goto ReturnToLabel

:ReturnToLabel
If %ReturnLabel% = ""
	Goto Main
Endif
Goto %ReturnLabel%

:EndItemsGS

