'' For blending channels with and individually
Union __colour
	c As UInteger
	Type
		b As UByte
		g As UByte
		r As UByte
		a As UByte
	End Type
End Union 

'' Custom Blending function for the playerLight mode
Function channelAnd( ByVal p1 As UInteger, ByVal p2 As UInteger, ByVal param As Any Ptr ) As UInteger
	Dim c1 As __colour
	Dim c2 As __colour
	Dim c3 As __colour
	
	c1.c = p1
	c2.c = p2
	
	c3.r = c1.r * (c2.r/255)
	c3.g = c1.g * (c2.g/255)
	c3.b = c1.b * (c2.b/255)
	c3.a = c1.a * (c2.a/255)
	
	Return c3.c
End Function

'' Handle the tilemap, player and objects in one object
type room
	'' The important stuff
	map		As Screen
	player		As Player
	
	'' The screen margin around the player
	marginY		As Integer = ((__YRES/__SCALE)/2)-2
	marginX		As Integer = ((__XRES/__SCALE)/2)-2

	objects(Any)	As gameObject
	
	'' Each element is the label in the code to jump to when the player steps onto that square
	trigger(__MAP_SIZE,__MAP_SIZE)	As String
	
	attackTrigger	As String ' The attack trigger 
	
	'' These are needed so that triggers aren't re-activated until
	'' the player leaves the tile
	currentTrigger	As String
	prevTrigger	As String
	
	playerX		As Integer
	playerY		As Integer
	
	playerZindex	As Integer = __LAYER_COUNT__ - 1
	
	'' "lighting"
	playerLight	As Any Ptr
	pl_refX		As Integer
	pl_refY		As Integer
	
	'' Able to disable player input while NPCs move etc.
	disablePlayerInput As Boolean
	
	'' These were going to be callbacks for the script but you can't create function
	'' pointers to member functions for some reason? Its in the documentation and 
	'' didn't work so I am pretty sure thats the case
	Declare Sub LoadTileset( ByVal As String )
	Declare Sub LoadTileMap( ByVal As String )
	
	Declare Sub LoadPlayerSprite( ByVal As String, ByVal As Integer, ByVal As Integer, ByVal As Integer = 1 )
	Declare Sub RefreshTileMap()
	
	Declare Function getTrigger() As String
	
	'' Manipulate objects
	Declare Function addObject( ByVal As String, ByVal As Integer, ByVal As Integer, ByVal As Integer = 1 ) As Integer
	Declare Sub setObject( ByVal As Integer, ByVal As String, ByVal As Integer, ByVal As Integer, ByVal As Integer = 1 )
	
	'' Running the game
	Declare Sub Update()
	Declare Sub UpdateObjects()
	
	'' Lighting engine
	Declare Sub setLighting( ByVal As String, ByVal As Integer, ByVal As Integer )
	Declare Sub deleteLight()
	Declare Sub drawLighting()
	
	''
	Declare Constructor ()
	Declare Sub Viewport()
end type

'' Shade everything around the player
Sub room.setLighting( ByVal imageFile As String, ByVal w As Integer, ByVal h As Integer )
	playerLight = ImageCreate( w, h, rgb(255,255,255))
	
	LoadImageFile(imageFile, playerLight)
	
	pl_refX = w/2
	pl_refY = h/2
End Sub

'' Delete the light that was set
Sub room.deleteLight()
	If playerLight <> 0 Then
		ImageDestroy(playerLight)
		PlayerLight = 0
	Endif
End Sub

'' draw the lighting around the player
Sub room.drawLighting()
	If playerLight <> 0 Then
		Dim As Any Ptr	Lighting = imageCreate( __XRES, __YRES, rgb(0,0,0))
		
		Put Lighting, (this.player.posx-pl_refX, this.player.posy-pl_refY), playerLight, PSET
		
		Put (0,0), Lighting, CUSTOM, @channelAnd
		
		ImageDestroy(Lighting)
	Endif
End Sub

Constructor room()
	'' Make sure that the tilemap object is initialised so that
	'' it creates needed image buffers etc. 
	this.map.init()
	
	this.map.vp_x = 0
	this.map.vp_y = 0
	
	this.map.vp_w = (__XRES/__SCALE)
	this.map.vp_h = (__YRES/__SCALE)
End Constructor

Sub room.LoadTileSet( ByVal tileset As String )
	' Script loads the tile set
	this.map.LoadTiles( tileset )
End Sub

Sub room.LoadTileMap( ByVal tilemap As String )
	' Script loads the tile map
	this.map.LoadMap( tilemap )
	this.map.refresh()
	
	' remove old triggers
	For x As Integer = 0 to __MAP_SIZE
		For y As Integer = 0 to __MAP_SIZE
			this.trigger(x,y) = ""
		Next
	Next
	
	' Clear old objects
	ReDim this.objects(-1) As gameObject
End Sub

Sub room.LoadPlayerSprite( ByVal filename As String, ByVal w As Integer, ByVal h As Integer, ByVal a As Integer = 1 )
	' Script loads a player sprite
	this.player.load( filename, w, h, IIF(a,a,1) )
End Sub

Function room.addObject( ByVal filename As String, ByVal w As Integer, ByVal h As Integer, ByVal a As Integer = 1 ) As Integer
	Dim As Integer count = UBound (this.objects)+1
	
	ReDim Preserve this.objects( count ) as gameObject
	
	this.setObject( count, filename, w, h, a )
	
	Return count
End Function

Sub room.setObject( ByVal sID As Integer, ByVal filename As String, ByVal w As Integer, ByVal h As Integer, ByVal a As Integer = 1 )
	this.objects(sID).load( filename, w, h, IIF(a, a, 1) )
End Sub

Sub room.updateObjects()
	For i As Integer = 0 to UBound(this.objects)
		this.objects(i).updateMovement(this.map.vp_sx, this.map.vp_sy)
	Next
End Sub

Sub room.RefreshTileMap()
	this.map.refresh()
End Sub

Function room.getTrigger() As String
	'' Object triggers '''''''''''''''''''''''''''''''''''''''''''''''''
	For i As Integer = 0 to UBound(this.objects)
		If this.objects(i).disabled = false Then
			'' Object has reached its target position
			If this.objects(i).stoppedMoving Then
				Return this.objects(i).movementDoneTrigger
				
			'' Player is within interaction distance
			ElseIf this.objects(i).distanceTo(this.player) < 15 Then
				If getUserKey(kbd_Action, true) Then
					Return this.objects(i).PlayerActionTrigger
				Else
					Return this.objects(i).PlayerTouchTrigger
				Endif
				
			Endif
		Endif
	Next
	
	'' Attack/jump/action key trigger ''''''''''''''''''''''''''''''''''
	If getUserkey(kbd_Attack, False) Then
		Return this.attackTrigger
	Endif
	
	'' Map tile triggers''''''''''''''''''''''''''''''''''''''''''''''''
	'' Flag 3 means a trigger wont trigger unless the player presses 'e'
	If map.tiles(playerX,playerY).flag(3) Then
		If getUserKey(kbd_Action, true) Then
			return trigger( playerX, playerY )
		Endif
		
	'' Only retrigger when the same trigger on the same tile
	'' wasnt just activated
	Elseif currentTrigger <> prevTrigger Then
		return trigger( playerX, playerY )
	Endif
	
	'' default to do nothing
	Return ""
End Function

''''''
Sub room.Update()	
	ScreenLock
		' Blank the screen
		Line (0,0)-((__XRES/__SCALE),(__YRES/__SCALE)), rgb(0,0,0), BF
		Locate 1,1

		'' Tilemap layers
		For i As Integer = 0 to __LAYER_COUNT__
			this.map.draw(i)
			
			'' Draw objects on correct layer
			For j As Integer = 0 to UBound( this.objects )
				If (this.objects(j).zPosition = i) and (this.objects(j).disabled = false) Then
					this.objects(j).update()
				Endif
			Next
			
			'' Draw the player on the correct layer
			If i = this.playerZindex Then
				this.player.update()
			Endif
		Next
		
		'' Draw lighting overlay
		drawLighting()
		
		scaleScreen()
	ScreenUnLock
	
	'' Player inputs
	If not disablePlayerInput Then
		player.input( this.map )
	Endif
	
	'' Update objects
	this.updateObjects()
	
	'' Autoscroll the viewport
	this.viewport()
	
	'' Update trigger
	player.onTile(map, playerX, playerY)
	
	prevTrigger = currentTrigger
	currentTrigger = trigger(playerX,PlayerY) & "." & _
			 playerX & "." & playerY
			 
	If prevTrigger = "" Then
		prevTrigger = currentTrigger
	Endif
End Sub

Sub room.viewport()
	'' Taken from old version
	if player.posy > map.vp_h - marginY and map.vp_sy < ((__TILE_SIZE*__MAP_SIZE)-map.vp_h) then
		map.vp_sy += player.walk_speed
		player.posy -= player.walk_speed
	elseif player.posy < marginY and map.vp_sy > 1 then
		map.vp_sy -= player.walk_speed
		player.posy += player.walk_speed
	endif
	if player.posx > map.vp_w - marginX and map.vp_sx < ((__TILE_SIZE*__MAP_SIZE)-map.vp_w) then
		map.vp_sx += player.walk_speed
		player.posx -= player.walk_speed
	elseif player.posx < marginX and map.vp_sx > 1 then
		map.vp_sx -= player.walk_speed
		player.posx += player.walk_speed
	endif
End Sub

