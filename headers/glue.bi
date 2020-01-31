'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' This file is supposed to be all of the messy glue logic
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'' Unashamedly stolen from the forum 
Function RegulateFPS(Byval MyFps As Long,Byref fps As Long=0) As Long
	Static As Double timervalue,_lastsleeptime,t3,frames
	frames+=1
	If (Timer-t3)>=1 Then t3=Timer:fps=frames:frames=0
	Var sleeptime=_lastsleeptime+((1/myfps)-Timer+timervalue)*1000
	If sleeptime<1 Then sleeptime=1
	_lastsleeptime=sleeptime
	timervalue=Timer
	Return sleeptime
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Overworld related procedures
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Function gameCallback( arg(Any) As String, thisScript As script Ptr ) As Integer
	Static gameRoom As room	' wheeeeeee I hate this but whatevs
	' its only like, 1 step removed from a global varible but 
	' less useful because I can only access it from this function.
	' I don't think it is the intended use case for Static either
	' (to store such a large data structure)

	Select Case arg(0)
	
	'' Load and immediately display an image without cacheing it
	Case "Splash"
		Dim As Any Ptr splash = ImageCreate( __xres, __yres, rgb(0,0,0) )
		
		LoadImageFile(arg(1), splash)
		Put (0,0), splash, PSET
		ImageDestroy(splash)
		
		If arg(2) <> "" Then
			Sleep val(arg(2)), 1
		Endif
		
		Return -1
	
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	'' Room configuration
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	Case "LoadTileMap"
		gameRoom.LoadTileMap(arg(1))
		Return -1
		
	Case "LoadTileSet"
		gameRoom.LoadTileSet(arg(1))
		Return -1
		
	Case "RefreshTiles"
		gameRoom.RefreshTileMap()
		Return -1
		
	Case "SetTile"
		Dim As Integer tx = val( arg(1) )
		Dim As Integer ty = val( arg(2) )
		Dim As Integer tz = val( arg(3) )
		
		Dim As Integer tID = val( arg(4) )
		
		'' Only change the solid flag if a flag was
		'' specified
		Select Case arg(5)
		
		Case "SOLID"
			gameRoom.map.tiles(tx,ty).solid = 1
			
		Case "CLEAR"
			gameRoom.map.tiles(tx,ty).solid = 0
		
		End Select
		
		'' If no layer was specified then default to layer 0
		If arg(4) = "" Then
			tz = 0
			tID = val(arg(3))
		Endif
		
		'' Set the tileID
		gameRoom.map.tiles(tx,ty).tID(tz) = tID
		
		'' Redraw everything
		gameRoom.RefreshTileMap()
		Return -1
		
	Case "Trigger"
		Dim As Integer	tgrX, tgrY
		
		tgrX = val( arg(1) )
		tgrY = val( arg(2) )
		
		gameRoom.trigger(tgrX,tgrY) = arg(3)
		
		Return -1
	
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	'' Player Control
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''	
	Case "Player"
	
		Select Case arg(1)
		
		Case "Sprite"
			' Load a player sprite
			gameRoom.LoadPlayerSprite(arg(2), val(arg(3)), val(arg(4)), val(arg(5)))
			
		Case "Position"
			gameRoom.player.posx = (val( arg(2) )*32) + 16 - gameRoom.map.vp_sx
			gameRoom.player.posy = (val( arg(3) )*32) + 16 - gameRoom.map.vp_sy
			
			' Fix the viewport position (this is kind of a hack I wrote 
			' the player and viewport code a long time ago and can't get it
			' to do what I want now
			For i As Integer = 0 to 1024
				gameRoom.viewport()
			Next
			
		Case "ZIndex"
			gameRoom.playerZIndex = val( arg(2) ) 
			
		Case "Speed"
			gameRoom.player.walk_speed = val( arg(2) )
			
		Case "DisableInput"
			gameRoom.disablePlayerInput = true
		
		Case "EnableInput"
			gameRoom.disablePlayerInput = false
			
		Case "SimpleCollision"
			gameRoom.player.simple_collision = true
			
		Case "FullCollision"
			gameRoom.player.simple_collision = false
		
		Case Else
			thisScript->sendError("Unknown Player command, '" & arg(1) & "'", true)
		
		End Select
		
		Return -1
		
	'' Rom lighting
	Case "Light"
		Select Case arg(1)
		
		Case "Set"
			gameRoom.deleteLight()
			gameRoom.setLighting( arg(2), val(arg(3)), val(arg(4)) )
			Return -1
			
		Case "Radius"
			'' Set vars
			Dim As Integer radius = val(arg(2))
			
			gameRoom.pl_refx = radius
			gameRoom.pl_refy = radius
			
			'' Clear potential old image
			gameRoom.deleteLight()
			
			'' Create a buffer
			gameRoom.playerLight = imageCreate((radius+2)*2, (radius+2)*2, rgb(0,0,0))
			
			'' Draw the circle
			Circle gameRoom.playerLight, (radius+2, radius+2), radius, rgb(255,255,255),,,,F
			Return -1
		
		Case "Delete"
			gameRoom.deleteLight()
			Return -1
		
		End Select
		
		thisScript->senderror("Expected Set, Radius or Delete, found '" & arg(1) & "'")
		
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	'' Object Control
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	Case "Object"
		
		Select Case arg(1)
		
		Case "Clear"
			ReDim gameRoom.objects(-1) As gameObject
		
		Case "Add"
			Dim As String varName = arg(2)
			Dim As String imageName = arg(3)
			Dim As Integer w = val( arg(4) )
			Dim As Integer h = val( arg(5) )
			Dim As Integer a = val( arg(6) )
			
			Dim As Integer objectID
			
			objectID = gameRoom.addObject( imageName, w, h, a )
			
			' Set the variable to have the sprite's ID
			thisScript->stack.setVar(varName, objectID)
			
		Case "Set"
			Dim As Integer ObjectID = Val(arg(2))
			Dim As String imageName = arg(3)
			Dim As Integer w = val( arg(4) )
			Dim As Integer h = val( arg(5) )
			Dim As Integer a = val( arg(6) )
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			
			gameRoom.setObject( ObjectID, imageName, w, h, a )
			
		Case "Trigger_playerAction"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).playerActionTrigger = arg(3)
			
		Case "Trigger_playerTouch"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).playerTouchTrigger = arg(3)
			
		Case "Trigger_MovementEnd"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).movementDoneTrigger = arg(3)
			
		Case "Pos"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).SetPos( val(arg(3)), val(arg(4)) )
			
		Case "MoveTo"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).MoveTo( val(arg(3)), val(arg(4)) )
			
		Case "Speed"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).movespeed = val(arg(3))
			
		Case "Disable"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).disabled = true
			
		Case "Enable"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).disabled = true
			
		Case "Animate"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).animateDefault = true
			
		Case "NoAnimate"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).animateDefault = false
			
		Case Else
			thisScript->sendError("Unknown Object command, '" & arg(1) & "'", true)
			
		End Select
		
		Return -1
	
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	'' Main loop
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	Case "RunGame","ResumeGame"
		' This is basically the main game loop
		Do
			gameRoom.update()
			
			'' Check triggers
			Dim As String trigger = gameRoom.getTrigger()
			
			If trigger <> "" Then
				thisScript->seekTo(":" & trigger, true)
				Exit Do
			Endif
			
			If getUserKey(kbd_Close, True) Then
				End
			Endif
			
			Sleep RegulateFPS(30),1
		Loop Until getUserKey(kbd_Quit, true)
		
		'' Set/update variables for use in the script
		thisScript->stack.setVar("_PlayerX", gameRoom.playerX)
		thisScript->stack.setVar("_PlayerY", gameRoom.playerY)
		thisScript->stack.setVar("_PlayerZ", gameRoom.playerZIndex)
		
		Return -1
		
	Case Else
		Return 0
		
	End Select
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Menu and text procedures
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Function textAndMenuCallback( arg(Any) As String, thisScript As script Ptr ) As Integer
	Static As userChooser	selector

	Select Case arg(0)
	
	Case "Dialouge"
		dialouge( arg(1), IIF( arg(2) = "false", false, true) )
		Return -1
		
	Case "TextSpeed"
		textSpeed = val(arg(1))
		Return -1
		
	Case "Transition"
		Select Case arg(1)
		
		Case "FADE"
			Transition(tFade)
		
		Case "BLINDS"
			Transition(tBlinds)
			
		Case Else
			thisScript->SendError("Unknown transition type, " & arg(1))
			
		End Select
		
		Return -1
		
	Case "Confirm"
		Dim As String gotoLabel = confirm( arg(1), arg(2) )
		
		If gotoLabel <> "" Then
			thisScript->seekTo( ":" & gotoLabel, true )
		Endif
		
		Return -1
		
	Case "Option"
		Dim As String gotoLabel
		
		Select Case arg(1)
		
		Case "Add"
			selector.AddOption( arg(3), arg(2) )
		
		Case "Select"
			gotoLabel = selector.ChooseOption( arg(2) )
			
		Case Else
			thisScript->sendError("Expected Add or Choose, found '" & arg(1) & "'")
		
		End Select
		
		If gotoLabel <> "" Then
			thisScript->seekTo( ":" & gotoLabel, true )
		Endif
		
		Return -1
		
	'''''''''''''''''''
	Case "Background"
		LoadImageFile(arg(1), Screenptr)
	
	Case Else
		Return 0
		
	End Select
End Function

