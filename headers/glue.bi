'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' This file is supposed to be all of the messy glue logic
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

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
		debugPrint("Set trigger " & arg(1) & "," & arg(2) & " to " & arg(3))
		
		Dim As Integer	tgrX, tgrY
		
		tgrX = val( arg(1) )
		tgrY = val( arg(2) )
		
		gameRoom.trigger(tgrX,tgrY) = arg(3)
		
		Return -1
	
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
	'' Player Control
	'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''	
	Case "ActionTrigger"
		' the trigger to activate when the player presses the action button
		' See kbd_Attack in controls.bi for the control mapping
		gameRoom.attackTrigger = arg(1)
		
		Return -1
		
	Case "Player"
	
		Select Case arg(1)
		
		Case "Sprite"
			' Load a player sprite
			gameRoom.LoadPlayerSprite(arg(2), val(arg(3)), val(arg(4)), val(arg(5)))
			
		Case "Position"
			gameRoom.player.posx = (val( arg(2) )*__TILE_SIZE) + (__TILE_SIZE/2) - gameRoom.map.vp_sx
			gameRoom.player.posy = (val( arg(3) )*__TILE_SIZE) + (__TILE_SIZE/2) - gameRoom.map.vp_sy
			
			' Fix the viewport position (this is kind of a hack I wrote 
			' the player and viewport code a long time ago and can't get it
			' to do what I want now
			For i As Integer = 0 to 1024
				gameRoom.viewport()
			Next
			
		Case "ZIndex"
			gameRoom.playerZIndex = val( arg(2) ) 
			
		Case "Speed"
			gameRoom.player.walk_delay = val( arg(2) )
			
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
			debugPrint("Set room light to file " & arg(2))
			
			gameRoom.deleteLight()
			gameRoom.setLighting( arg(2), val(arg(3)), val(arg(4)) )
			Return -1
			
		Case "Radius"
			debugPrint("Set room light size to " & arg(2))
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
			debugPrint("Remove room light")
			
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
			
			debugPrint("Explicit clear room objects...")
		
		Case "Add"
			Dim As String varName = arg(2)
			Dim As String imageName = arg(3)
			Dim As Integer w = val( arg(4) )
			Dim As Integer h = val( arg(5) )
			Dim As Integer a = val( arg(6) )
			
			Dim As Integer objectID
			
			debugPrint("Add new object...")
			
			objectID = gameRoom.addObject( imageName, w, h, a )
			
			' Set the variable to have the sprite's ID
			thisScript->stack.setVar(varName, objectID)
			
			debugPrint(" -> Variable " & varName & " now contains ObjectID " & objectID)
			
		Case "Set"
			Dim As Integer ObjectID = Val(arg(2))
			Dim As String imageName = arg(3)
			Dim As Integer w = val( arg(4) )
			Dim As Integer h = val( arg(5) )
			Dim As Integer a = val( arg(6) )
			
			debugPrint("Update object " & arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			
			gameRoom.setObject( ObjectID, imageName, w, h, a )
			
		Case "Trigger_playerAction"
			Dim As Integer ObjectID = Val(arg(2))
			
			debugPrint("Update object " & arg(2) & " with playerAction trigger " & arg(3))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).playerActionTrigger = arg(3)
			
		Case "Trigger_playerTouch"
			Dim As Integer ObjectID = Val(arg(2))
			
			debugPrint("Update object " & arg(2) & " with playerTouch trigger " & arg(3))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).playerTouchTrigger = arg(3)
			
		Case "Trigger_MovementEnd"
			Dim As Integer ObjectID = Val(arg(2))
			
			debugPrint("Update object " & arg(2) & " with MovementEnd trigger " & arg(3))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).movementDoneTrigger = arg(3)
			
		Case "Pos"
			Dim As Integer ObjectID = Val(arg(2))
			
			debugPrint("Set object " & arg(2) & " position to " & arg(3) & "," & arg(4))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).SetPos( val(arg(3)), val(arg(4)) )
			
		Case "MoveTo"
			Dim As Integer ObjectID = Val(arg(2))
			
			debugPrint("Move object " & arg(2) & " to " & arg(3) & "," & arg(4))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).MoveTo( val(arg(3)), val(arg(4)) )
			
		Case "Speed"
			Dim As Integer ObjectID = Val(arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).movespeed = val(arg(3))
			
		Case "Disable"
			Dim As Integer ObjectID = Val(arg(2))
			
			debugPrint("Disable object " & arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).disabled = true
			
		Case "Enable"
			Dim As Integer ObjectID = Val(arg(2))
			
			debugPrint("Enable object " & arg(2))
			
			If ObjectID > UBound( gameRoom.objects) Then:thisScript->sendError("Invalid ObjectID."):Endif
			gameRoom.objects(ObjectID).disabled = false
			
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
				debugPrint("Trigger " & trigger & " activated...")
				
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
	Static As userChooser	selector	' For adding options to 
	Static As String	textScreen	' The full screen text

	Select Case arg(0)
	
	'' I can't spell and I wrote this so it caters to me hahahahahah
	Case "Dialouge","Dialogue"
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
		
	Case "Text"
		Select Case arg(1)
		
		Case "Add"
			textScreen += arg(2) & chr(10)
			Return -1
			
		Case "Show"
			dialouge(textScreen, IIF( arg(2) = "false", false, true ), true)
			textScreen = ""
			
			Return -1
			
		End Select
		
		thisScript->sendError("Text does not have an option '" & arg(1) & "'")
		Return 0
		
	Case "Option"
		Dim As String gotoLabel
		
		Select Case arg(1)
		
		Case "Add"
			selector.AddOption( arg(3), arg(2) )
		
		Case "Select"
			gotoLabel = selector.ChooseOption( arg(2) )
			
		Case "SelectBig"
			gotoLabel = selector.ChooseOption( "", true )
			
		Case Else
			thisScript->sendError("Expected Add or Choose, found '" & arg(1) & "'")
		
		End Select
		
		If gotoLabel <> "" Then
			thisScript->seekTo( ":" & gotoLabel, true )
		Endif
		
		Return -1
		
	'''''''''''''''''''
	'' User input
	Case "NumberInput"
		Dim As Integer minVal = val(arg(2))
		Dim As Integer maxVal = val(arg(3))
		
		Dim As Integer result
		
		Dim As String resultVar = arg(1)
		
		result = getNumberAmount(minVal, maxVal)
		
		thisScript->stack.setVar(resultVar, result)
		
	'''''''''''''''''''
	Case "Background"
		'' Splash works better so use it instead
		LoadImageFile(arg(1), Screenptr)
		
		Return -1
		
	Case "Font"
		If fileExists(arg(1)) Then
			drawString(0,0,"",,,arg(1))
		Endif
		
		Return -1
	
	Case Else
		Return 0
		
	End Select
End Function

'' Inventory callbacks
Function inventoryManagerCallback( arg(Any) As String, thisScript As Script Ptr ) As Integer
	Static As inventoryManager inv	' The inventory
	
	Select Case arg(0)
	
	Case "Inventory"
		Select Case arg(1)
		
		Case "Add"
			Dim As String itemTrigger	= arg(2)
			Dim As String itemName		= arg(3)
			Dim As Integer quantity		= val(arg(4))
			Dim As String description	= arg(5)
			Dim As Boolean keyItem		= IIF(arg(6) = "true", true, false)
			
			inv.addItem(itemName, quantity, itemTrigger, description, keyItem)
			
			Return -1
			
		Case "Rem"
			inv.remItem(arg(2), IIF(arg(3) = "", 1, val(arg(3))))
			
			Return -1
			
		Case "Use"
			Dim As String triggerLabel
			
			triggerLabel = inv.useItem(arg(2))
			
			If triggerLabel <> "" Then
				thisScript->seekTo(":" & triggerLabel, true)
			Endif
			
			Return -1
			
		Case "Save"
			inv.saveInventory(arg(2))
			
			Return -1
			
		Case "Load"
			inv.loadInventory(arg(2))
			
			Return -1
			
		Case "Show"
			' Show the player their inventory and let them choose items etc.
			Dim As String triggerLabel
			
			triggerLabel = inv.InventoryScreen()
			
			If triggerLabel <> "" Then
				thisScript->seekTo(":" & triggerLabel, true)
			Endif
			
			Return -1
		
		End Select
		
		thisScript->sendError("Unknown inventory function, '" & arg(1) & "'")
		Return 0
		
	Case Else
		Return 0
		
	End Select
End Function

'' Audio callbacks
Function musicAndSoundCallback( arg(Any) As String, thisScript As script Ptr ) As Integer
        #ifdef _SND_SUPPORT_
	Static As Mix_Music Ptr		bgMusic
        #endif
	
	Select Case arg(0)
	
	Case "PlayMusic"
		#ifdef _SND_SUPPORT_
			If bgMusic <> 0 Then
				'' Unload the old music
				Mix_FreeMusic(bgMusic)
				bgMusic = 0
			Endif
			
			'' Load the music
			bgMusic = Mix_LoadMus(arg(1))
			Mix_PlayMusic(bgMusic, true)
			
			debugPrint("Playing music file " & arg(1))
		#else
			debugPrint(sound_disabled_str)
		#endif
		
		Return -1
		
	Case "StopMusic"
		#ifdef _SND_SUPPORT_
			Mix_HaltMusic()
			debugPrint("Stopping sound playback.")
		#else
			debugPrint(sound_disabled_str)
		#endif
		
		Return -1
		
	Case "PauseMusic"
		#ifdef _SND_SUPPORT_
			Mix_PauseMusic()
			debugPrint("Paused music playback.")
		#else
			debugPrint(sound_disabled_str)
		#endif
		
		Return -1
		
	Case "ResumeMusic"
		#ifdef _SND_SUPPORT_
			Mix_ResumeMusic()
			debugPrint("Resume paused music.")
		#else
			debugPrint(sound_disabled_str)
		#endif
		
		Return -1
		
	Case "MusicVolume"
		#ifdef _SND_SUPPORT_
			Mix_VolumeMusic(val(arg(1)))
			debugPrint("Set music volume to " & arg(1) & ".")
		#else
			debugPrint(sound_disabled_str)
		#endif
		
		Return -1
		
	Case "SetDialogue_SFX"
		debugPrint("Set SFX file for dialogue...")
		DialogueSound( arg(1), false )
		
		Return -1
		
	Case "PlaySFX"
		#ifdef _SND_SUPPORT_
			debugPrint("Play sound effect " & arg(1))
			Dim As Mix_chunk Ptr	sfx
			
			sfx = Mix_LoadWav(arg(1))			
			Mix_PlayChannel(-1,sfx,0)
			
			Mix_FreeChunk(sfx):sfx = 0
		#else
			debugPrint(sound_disabled_str)
		#endif
		
		Return -1
		
	End Select
	
	Return 0
End Function

