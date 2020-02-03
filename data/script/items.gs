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

:ReturnToLabel
If %ReturnLabel% = ""
	Goto Main
Endif
Goto %ReturnLabel%

:EndItemsGS

