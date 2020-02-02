'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Manage the player's inventory
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Type inventoryItem
	name 		As String*32	' The display name of the item
	trigger 	As String*32	' If the player "uses" the item, use this code
	count 		As Integer	' How many does the player have?
	
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
	Declare Sub addItem( ByVal As String, ByVal As Integer = 1, ByVal As String = "", ByVal As Boolean = false )
	Declare Sub remItem( ByVal As String, ByVal As Integer = 1 )
	
	' Check if the player has a certain item
	Declare Function hasItem( ByVal As String ) As Boolean
	
	' Remove one item from the inventory and return the trigger
	Declare Function useItem( ByVal As String ) As String
	
	' Save/load the inventory
	Declare Sub saveInventory( ByVal As String )
	Declare Sub loadInventory( ByVal As String )
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
			ByVal keyItem As Boolean = false )
			
	Dim As Integer count = UBound( this.item ) + 1
	Dim As Integer ID = this.getItemID( itemName )
	
	If ID = -1 Then
		ReDim Preserve this.item( count ) As inventoryItem
		
		this.item(count).name = itemName
		this.item(count).trigger = trigger
		this.item(count).count = quantity
		this.item(count).key = keyItem
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
		
		If this.item(ID).count < 0 Then
			' The user has none left
			' but currently I don't know of an easy way to delete an array index so instead
			' we will ignore items with a quantity less than 1 when displaying menus and saving/loading
			' the inventory
			this.item(ID).count = 0
		Endif
	Endif
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
		Put #file,,item(i)
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

