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
	Declare Sub addItem( ByVal As String, ByVal As Integer = 1, ByVal As Boolean = false )
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
	Return -1
End Function

Sub inventoryManager.addItem( ByVal itemName As String, ByVal quantity As Integer = 1, ByVal keyItem As Boolean = false )
End Sub

Sub inventoryManager.remItem( ByVal itemName As String, ByVal quantity As Integer = 1 )
End Sub

Function inventoryManager.hasItem( ByVal itemName As String ) As Boolean
	Return false
End Function

Function inventoryManager.useItem( ByVal itemName As String ) As String
	Return ""
End Function

Sub inventoryManager.saveInventory( ByVal fileName As String )
End Sub

Sub inventoryManager.loadInventory( ByVal fileName As String )
End Sub

