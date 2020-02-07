'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Manage the player's inventory
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
#include "file.bi"

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
	Declare Sub clearItems()
	
	' Check if the player has a certain item
	Declare Function hasItem( ByVal As String ) As Boolean
	
	' Remove one item from the inventory and return the trigger
	Declare Function useItem( ByVal As String ) As String
	
	' Save/load the inventory
	Declare Sub saveInventory( ByVal As String )
	Declare Sub loadInventory( ByVal As String )
	
	' Show the GUI
	Declare Function InventoryScreen(ByVal As String = "Use", _
					  ByVal As String = "Items", _
					  ByVal As Boolean = true) As String
End Type

Function inventoryManager.getItemID( ByVal trigger As String ) As Integer
	Dim As Integer count = UBound( this.item )
	
	For i As Integer = 0 to count
		debugPrint( " -> " & this.item(i).trigger & " - " & trigger)
		If this.item(i).trigger = trigger Then
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
	Dim As Integer ID = this.getItemID( trigger )
	
	debugPrint("Add new item " & itemName & " to inventory...")
	
	If ID = -1 Then
		debugPrint(" -> Item does not exist in inventory (" & ID & "), adding a new one.")
		ReDim Preserve this.item( count ) As inventoryItem
		
		this.item(count).name = itemName
		this.item(count).trigger = trigger
		this.item(count).count = quantity
		this.item(count).key = keyItem
		this.item(count).description = description
	ElseIf this.item(ID).key Then
		' The user already has this key item
		debugPrint(" -> User already has one and it is a key item, not adding another...")
	Else
		debugPrint(" -> Item has ID " & ID & ", so incrimenting amount...")
		this.item(ID).count += quantity
	Endif
End Sub

Sub inventoryManager.remItem( ByVal trigger As String, ByVal quantity As Integer = 1 )
	Dim As Integer ID = getItemId(trigger)
	
	debugPrint("Remove " & quantity & " of " & trigger & "(" & ID & ") from inventory...")
	
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
	
	debugPrint("Delete item " & ID & " from inventory...")
	
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
	
	debugPrint(" -> 1 item deleted from " & (count+1) & " items, leaving " & newID & " items.")
End Sub

Sub inventoryManager.clearItems()
	'' Clear the inventory
	ReDim this.item(-1) As inventoryItem
End Sub

Function inventoryManager.hasItem( ByVal trigger As String ) As Boolean
	If getItemID(trigger) > -1 Then
		Return true
	Else
		Return false
	Endif
End Function

Function inventoryManager.useItem( ByVal trigger As String ) As String
	Dim As Integer ID = getItemID(trigger)
	
	If ID = -1 Then
		Return ""
		
	Elseif item(ID).count > 0 Then
		this.remItem(trigger)
		
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
	
	If FileExists(fileName) Then
		Open fileName For Binary As #file
		
		Get #file,,itemCount
		
		ReDim this.item(itemCount) As inventoryItem
		
		For i As Integer = 0 to itemCount
			Get #file,,item(i)
		Next
		
		Close #file
	Endif
End Sub

Function inventoryManager.InventoryScreen(ByVal useString As String = "Use", _
					  ByVal title As String = "Items", _
					  ByVal notShop As Boolean = true) As String
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
	
	'' What if the player has nothing
	If listLength <= 0 Then
		dialouge("Your inventory is empty...")
		Return ""
	Endif
	
	'' Main loop
	Do
		ScreenLock		
		' the box for the list
		menuBox(listX, listY, listW, listH)
		
		drawString(listX+16, listY+16, title, rgb(0,0,0))
		Line (listX+16,listY+26)-STEP(len(title)*8,0), rgb(0,0,0)
		
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
			
			'Draw String (listX+16, listY+36+((i-scroll)*10)), this.item(i).name, textColor
			'Draw String (listX+listW-16-(len(qstr)*8), listY+36+((i-scroll)*10)), qstr, qstrc
			
			drawString(listX+16, listY+36+((i-scroll)*10), this.item(i).name, textColor)
			drawString(listX+listW-16-(len(qstr)*8), listY+36+((i-scroll)*10), qstr, qstrc)
		Next
		
		If scroll+ListHeight < ListLength Then
			'Draw String (listX + (listW/2) - 12, listY + listH - 16), "...", rgb(0,0,0)
			drawString(listX + (listW/2) - 12, listY + listH - 16, "...", rgb(0,0,0))
		Endif
		
		' the box for the item description
		menuBox(descX, descY, descW, descH)
		c_drawText(this.item(selected).description, descX+16, descY+16, (descW-64)/8, 0)
		
		'' This is pruposefully the same as the uesrSelector one so that they can overlap when
		'' an item is selected, otherwise it looks garbage.
		drawButtonPrompt(_KEY_UP & "/" & _KEY_DN & " Select, " & _KEY_ACTION & " Confirm")
		
		ScreenUnLock
		
		'' Control scrolling
		If getUserKey(kbd_Up, false, 200) Then
			selected -= 1
		ElseIf getUserKey(kbd_Down, false, 200) Then
			selected += 1
		ElseIf getUserKey(kbd_Action, true) Then
			If (notShop = false) and (this.item(selected).key = true) Then
				' Can't sell key items
			Else
				selectionMenu.addOption(useString, "UseItem")
			Endif
			
			'' You can't drop key items
			If (this.item(selected).key = false) and (notShop) Then
				selectionMenu.addOption("Drop", "DropItem")
			Endif
			
			selectionMenu.addOption("Cancel", "")
			
			Select Case selectionMenu.chooseOption("What do you want to do?")
			
			Case "UseItem"
				debugPrint("Use item " & selected & ", jumping to " & this.item(selected).trigger)
				Return this.item(selected).trigger
			
			Case "DropItem"
				'' Drop an item or number of items
				Dim As Integer numberToDrop
				
				numberToDrop = getNumberAmount(0,this.item(selected).count)
				
				If numberToDrop > 0 Then
				If confirm("DROP", _
					"Are you sure you want to drop " & numberToDrop & "x " & this.item(selected).name & "(s)?") = "DROP" Then
				
					debugPrint("User wants to drop " & numberToDrop & " of " & selected)
					this.remItem(this.item(selected).name, numberToDrop)
					debugPrint(" -> Done")
					
					'' Update list size
					listLength = UBound(this.item)
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

