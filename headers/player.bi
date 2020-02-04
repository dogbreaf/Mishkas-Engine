#include once "fbgfx.bi"

Type player extends sprite
	walk_speed	As Integer = 1
	walk_delay	As Integer = 20
	
	walk_timer	As Double
	
	next_x		As Integer
	next_y		As Integer
	
	simple_collision	As Boolean = true

	declare sub input( ByRef room As Screen )

	declare sub onTile overload ( ByRef room As Screen, ByRef tx As Integer, ByRef ty As Integer )
	declare sub onTile overload ( ByVal x As Integer, ByVal y As Integer, ByRef room As Screen, ByRef tx As Integer, ByRef ty As Integer )

	declare sub move( ByVal xv As Integer, ByVal yv As Integer, ByRef room As screen )
End Type

Sub player.onTile( ByVal x As Integer, ByVal y As Integer, ByRef room As Screen, ByRef tx As Integer, ByRef ty As Integer )
	' Calculate the tile the player is currently positioned over

	tx = (x-room.vp_x+room.vp_sx-this.refx)/__TILE_SIZE
	ty = (y-room.vp_y+room.vp_sy-this.refy)/__TILE_SIZE
End Sub

Sub player.onTile( ByRef room As Screen, ByRef tx As Integer, ByRef ty As Integer )
	' Calculate the tile the player is currently positioned over
	this.onTile(this.posx, this.posy, room, tx, ty)
End Sub

Sub player.input( ByRef room As Screen )
	' default to no animation
	this.animate = 0
	
	' X and Y velocity 
	Dim As Integer xv, yv
	
	' Which animations do we use for which direction of travel
	Dim As Integer walk_normal_anim = 1
	Dim As Integer walk_up_anim = 1
	Dim As Integer walk_dn_anim = 1
	
	If this.animations > 1 Then
		walk_up_anim = 2
		walk_dn_anim = 3
	Endif

	' Check for movement using the WASD keys
	if getUserKey(kbd_Up, false, 0) then
		this.animate = walk_up_anim
		this.flip_x = 0
		yv += -walk_speed
	endif
	if getUserKey(kbd_Down, false, 0) then
		this.animate = walk_dn_anim
		this.flip_x = 0
		yv += walk_speed
	endif
	if getUserKey(kbd_Left, false, 0) then
		this.animate = walk_normal_anim
		this.flip_x = 1
		xv += -walk_speed
	endif
	if getUserKey(kbd_Right, false, 0) then
		this.animate = walk_normal_anim
		this.flip_x = 0
		xv += walk_speed
	endif
	
	this.move(xv, yv, room)
End Sub

Sub player.move( ByVal xv As Integer, ByVal yv As Integer, ByRef room As Screen ) 
	Dim As Boolean		collision
	Dim As Integer		nx,ny
	
	If simple_collision Then
		this.onTile ( this.posx+xv, this.posy+yv, room, nx, ny )

		If room.tiles(nx,ny).solid Then
			collision = true
		Endif
	Else
		this.onTile( this.posx+xv - this.refx, this.posy+yv - this.refy, room, nx, ny)
		If room.tiles(nx,ny).solid Then
			collision = true
		Endif
		
		this.onTile( this.posx+xv + this.refx, this.posy+yv + this.refy, room, nx, ny)
		If room.tiles(nx,ny).solid Then
			collision = true
		Endif
		
		this.onTile( this.posx+xv + this.refx, this.posy+yv - this.refy, room, nx, ny)
		If room.tiles(nx,ny).solid Then
			collision = true
		Endif
		
		this.onTile( this.posx+xv - this.refx, this.posy+yv + this.refy, room, nx, ny)
		If room.tiles(nx,ny).solid Then
			collision = true
		Endif
	Endif
	
	'' Two seperate IF statements to suppress warning about mixed boolean operators
	If (timer-this.walk_timer)*1000 > this.walk_delay Then
		If not collision then
			this.posx += xv
			this.posy += yv
		Endif
	Endif
	this.walk_timer = timer
End Sub

