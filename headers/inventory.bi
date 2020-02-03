'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Manage the player's inventory
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Type inventoryItem
	name 		As String*32	' The display name of the item
	trigger 	As String*32	' If the player "uses" the item, use this code
	count 		As Integer	' How many does the player have?
	
	description	As String*128	' The description of the item
	
	iconID		As Integer	' This is the ID of the item icon to use to represent the item
	
	key 		As Boolean	' Is this a Key Item?
End Type

Type inventoryManager
	' Items to be managed
	item(Any)	As inventoryItem
	
	' The image buffer containing the item icons
	' and assosciated data
	icons		As Any Ptr
	iconsize	As Integer = 32
	
	' Get the ID of an item
	Declare Function getItemID( ByVal As String ) As Integer
	
	' Add and remove items
	Declare Sub addItem( ByVal As String, ByVal As Integer = 1, ByVal As String = "", ByVal As String = "", ByVal As Boolean = false )
	Declare Sub remItem( ByVal As String, ByVal As Integer = 1 )
	
	Declare Sub deleteItem( ByVal As Integer )
	
	' Check if the player has a certain item
	Declare Function hasItem( ByVal As String ) As Boolean
	
	' Remove one item from the inventory and return the trigger
	Declare Function useItem( ByVal As String ) As String
	
	' Save/load the inventory
	Declare Sub saveInventory( ByVal As String )
	Declare Sub loadInventory( ByVal As String )
	
	' Show the GUI
	Declare Function InventoryScreen() As String
End Type

Function inventoryManager.getItemID( ByVal itemName As String ) As Integer
	Dim As Integer count = UBound( this.item )
	
	For i As Integer = 0 to count
		If this.item(i).name = itemName Then
			Return i
		Endif
	Next
	
	Return -1
End Function

Sub inventoryManager.addItem( ByVal itemName As String, _
			ByVal quantity As Integer = 1, _
			ByVal trigger As String = "", _
			ByVal description As String = "", _
			ByVal keyItem As Boolean = false )
			
	Dim As Integer count = UBound( this.item ) + 1
	Dim As Integer ID = this.getItemID( itemName )
	
	If ID = -1 Then
		ReDim Preserve this.item( count ) As inventoryItem
		
		this.item(count).name = itemName
		this.item(count).trigger = trigger
		this.item(count).count = quantity
		this.item(count).key = keyItem
		this.item(count).description = description
	ElseIf this.item(ID).key Then
		' The user already has this key item
	Else
		this.item(ID).count += quantity
	Endif
End Sub

Sub inventoryManager.remItem( ByVal itemName As String, ByVal quantity As Integer = 1 )
	Dim As Integer ID = getItemId(itemName)
	
	If ID > -1 Then
		' decriment the item quantity
		this.item(ID).count -= quantity
		
		If this.item(ID).count <= 0 Then
			' The user has none left
			deleteItem(ID)
		Endif
	Endif
End Sub

Sub inventoryManager.deleteItem( ByVal ID As Integer )
	'' Permanantly delete an item
	Dim As Integer count = UBound(item)
	Dim As Integer newID
	
	Dim As inventoryItem temp(count)
	
	For i As Integer = 0 to count
		temp(i) = this.item(i)
	Next
	
	ReDim this.item(count-1) As inventoryItem
	
	For i As Integer = 0 to count
		If i <> ID Then
			this.item(newID) = temp(i)
			newID += 1
		Endif
	Next 
End Sub

Function inventoryManager.hasItem( ByVal itemName As String ) As Boolean
	If getItemID(itemName) > -1 Then
		Return true
	Else
		Return false
	Endif
End Function

Function inventoryManager.useItem( ByVal itemName As String ) As String
	Dim As Integer ID = getItemID(itemName)
	
	If ID = -1 Then
		Return ""
		
	Elseif item(ID).count > 0 Then
		this.remItem(itemName)
		
		Return this.item(ID).trigger
	Endif
	
	Return ""
End Function

Sub inventoryManager.saveInventory( ByVal fileName As String )
	Dim As Integer file = FreeFile
	Dim As Integer itemCount = UBound(this.item)
	
	Open fileName For Binary As #file
	
	Put #file,,itemCount
	
	For i As Integer = 0 to itemCount
		If item(i).count > 0 Then
			Put #file,,item(i)
		Endif
	Next
	
	Close #file
End Sub

Sub inventoryManager.loadInventory( ByVal fileName As String )
	Dim As Integer file = FreeFile
	Dim As Integer itemCount
	
	Open fileName For Binary As #file
	
	Get #file,,itemCount
	
	ReDim this.item(itemCount) As inventoryItem
	
	For i As Integer = 0 to itemCount
		Get #file,,item(i)
	Next
	
	Close #file
End Sub

Function inventoryManager.InventoryScreen() As String
	'' Window box dimensions
	Dim As Integer listX, listY, listW, listH
	Dim As Integer descX, descY, descW, descH
	
	listW = __XRES/4
	listH = __YRES-256
	listX = __XRES - listW - 32
	listY = 32
	
	descW = __XRES-64
	descH = 128
	descX = 32
	descY = __YRES-160
	
	'' Some vars
	Dim As Integer scroll
	Dim As Integer selected
	
	Dim As Integer listHeight = (listH-128)/8 ' the number of items the list can display
	Dim As Integer listLength = UBound(this.item)
	
	'' Selector for when the user selects an item
	Dim As userChooser	selectionMenu
	
	'' Main loop
	Do
		ScreenLock		
		' the box for the list
		menuBox(listX, listY, listW, listH)
		
		Draw String (listX+16, listY+16), "Items", rgb(0,0,0)
		Line (listX+16,listY+26)-STEP(40,0), rgb(0,0,0)
		
		For i As Integer = scroll to (listHeight+scroll)
			If i > listLength Then
				Exit For
			Endif
			
			' Item quantity
			Dim As String qstr = "x" & this.item(i).count
			Dim As uInteger qstrc = rgb(128,128,128)
			
			' Which color to draw the text
			Dim As uInteger textColor = rgb(0,0,0)
			
			If this.item(i).key Then
				qstr = chr(9) & chr(183)
				qstrc = rgb(255,10,20)
			Endif
			
			If i = selected Then
				Line (listX+15, listY+35+((i-scroll)*10))-step(listW-32, 9), rgb(0,0,0), BF
				textColor = rgb(255,255,255)
			Endif
			
			Draw String (listX+16, listY+36+((i-scroll)*10)), this.item(i).name, textColor
			Draw String (listX+listW-16-(len(qstr)*8), listY+36+((i-scroll)*10)), qstr, qstrc
		Next
		
		If scroll+ListHeight < ListLength Then
			Draw String (listX + (listW/2) - 12, listY + listH - 16), "...", rgb(0,0,0)
		Endif
		
		' the box for the item description
		menuBox(descX, descY, descW, descH)
		drawText(this.item(selected).description, descX+16, descY+16, (descW-64)/8, 0)
		
		ScreenUnLock
		
		'' Control scrolling
		If getUserKey(kbd_Up, false, 200) Then
			selected -= 1
		ElseIf getUserKey(kbd_Down, false, 200) Then
			selected += 1
		ElseIf getUserKey(kbd_Action, true) Then
			selectionMenu.addOption("Use", "UseItem")
			
			'' You can't drop key items
			If this.item(selected).key = false Then
				selectionMenu.addOption("Drop", "DropItem")
			Endif
			
			selectionMenu.addOption("Cancel", "")
			
			Select Case selectionMenu.chooseOption("What do you want to do?")
			
			Case "UseItem"
				Return this.item(selected).trigger
			
			Case "DropItem"
				'' Drop an item or number of items
				Dim As Integer numberToDrop
				
				numberToDrop = getNumberAmount(0,this.item(selected).count)
				
				If numberToDrop > 0 Then
				If confirm("DROP", _
					"Are you sure you want to drop " & numberToDrop & "x " & this.item(selected).name & "(s)?") = "DROP" Then
				
					this.remItem(this.item(selected).name, numberToDrop)
				Endif
				Endif
			End Select
		Endif

		If selected < 0 Then:selected = 0:Endif
		If selected > listLength Then:selected = listLength:Endif
		
		If selected-scroll > listHeight Then
			scroll += 1
		ElseIf selected-scroll < 0 Then
			scroll -= 1
		Endif
		
		Sleep regulateFPS(60),1
	Loop Until getUserKey(kbd_Quit, true, 0)
	
	Return ""
End Function

