'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''
'' Old Sprite code
''
'' Not quite to my current standard but it works so I can't complain
''
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

#include once "fbgfx.bi"

#macro spriteDebug(text)
#Ifdef __DEBUG__
..Draw String (this.posx-this.refx, this.posy-this.refy-10), text
#Endif
#Endmacro

#Ifdef __DEBUG__
Dim shared __spriteUUIDTotal As Integer = 0
#Endif

#macro backbox()
#Ifdef __DEBUG__
Line ( this.posx-(this.refx*this.scale), this.posy-(this.refy*this.scale) )-step( this.frame_size*this.scale, this.frame_size*this.scale ), rgb(0,0,255), BF
#Endif
#Endmacro

#define __PI__ 3.1415926535897932

Declare Sub rotate(ByVal maxx As Double, _
		ByVal maxy As Double, _
		ByVal angle As Double, ByVal buf As Any Ptr)

Enum spriteFX
	sfx_none
	sfx_wiggle
	sfx_flAsh
	sfx_damage
	sfx_pixelate
End Enum

Type sprite
	buffer As fb.Image Ptr   ' Image buffer

	posx As Integer       ' the x position
	posy As Integer       ' the y position

	refx As Integer       ' the center reference point of sprite
	refy As Integer       '

	speed As Integer      ' The speed the sprite is moving at (pixels)
	direction As Double   ' The direction the sprite is moving in (degrees)

	frame_total As Integer ' Frame total
	frame_delay As Integer ' Frame delay (locked to sprite animation framerate)
	frame_index As Integer ' The current frame index
	frame_size As Integer  ' All sprites are Assumed to be square and the long Dimension of the image is the frames

	lAst_draw As Integer

	flip_x As Integer     ' Should the sprite be drawn horizontally flipped
	flip_y As Integer     ' vertical flip

	rotation As Double    ' Allow the sprite to be rotated by an arbitrary angle
	scale As Integer			' Allow the sprite to be scaled by a whole number

	animate As Integer    ' Should the sprite animate or not/animation ID
	animations As Integer ' Number of animations

	__int_framerefresh As Integer	' non-zero If the frame index changed

	#Ifdef __DEBUG__
	uuid As Integer
	#Endif

	Declare Function load( ByVal path As String, ByVal w As Integer, ByVal h As Integer, _
	ByVal animations As Integer = 1, ByVal frame_delay As Integer = 100 ) As Integer
	Declare Function update() As Integer

	Declare Function distanceTo overload ( ByRef object As Sprite ) As Integer
	Declare Function distanceTo overload ( ByVal xpos As Integer, ByVal ypos As Integer ) As Integer
	Declare Function touching ( ByRef object As Sprite ) As Integer
	Declare Function directionTo overload ( ByRef object As Sprite ) As Double
	Declare Function directionTo overload ( ByVal xpos As Integer, ByVal ypos As Integer ) As Double
	Declare Function inZone ( ByVal x1 As Integer, ByVal y1 As Integer, ByVal x2 As Integer, ByVal y2 As Integer ) As Integer
End Type

Function sprite.inZone ( ByVal x1 As Integer, ByVal y1 As Integer, ByVal x2 As Integer, ByVal y2 As Integer ) As Integer
	If this.posx > x1 and this.posx < x2 and this.posy > y1 and this.posy < y2 then
		Return 1
	Else
		Return 0
	Endif
End Function

Function sprite.directionTo( ByRef object As Sprite ) As Double
	Return this.directionTo(object.posx, object.posy)
End Function

Function sprite.directionTo( ByVal xpos As Integer, ByVal ypos As Integer ) As Double
	Dim As Integer a,b
	Dim As Double ret

	a = abs(this.posx-xpos)
	b = abs(this.posy-ypos)

	If xpos < this.posx and ypos < this.posy then
		ret = atn( b/a ) * (180/__PI__)
		ret += 180
	ElseIf xpos > this.posx and ypos > this.posy then
		ret = atn( b/a ) * (180/__PI__)
	ElseIf xpos > this.posx and ypos < this.posy then
		ret = atn( a/b ) * (180/__PI__)
		ret -= 90
	ElseIf xpos < this.posx and ypos > this.posy then
		ret = atn( a/b ) * (180/__PI__)
		ret += 90
	Else
		' we are right under our target but setting the speed to 0 might break something
		' so we set the angle to a random one to ensure that it is not unintentionally set to 0
		ret = rnd()*360
	Endif

	#Ifdef __DEBUG__
	Dim As Integer dbx, dby
	
	dbx = 32 * cos( ret * __PI__/180 )
	dby = 32 * sin( ret * __PI__/180 )

	' Draw a 32 pixel long line from the sprite to the direction of the point
	Line ( this.posx, this.posy )-STEP( dbx, dby ), rgb(255,0,255)
	#Endif

	Return ret
End Function

Function sprite.distanceTo( ByRef object As Sprite ) As Integer
	Return this.distanceTO(object.posx, object.posy)
End Function

Function sprite.distanceTo ( ByVal xpos As Integer, ByVal ypos As Integer ) As Integer
	Dim As Integer a, b
	
	a = abs(xpos-this.posx)
	b = abs(ypos-this.posy)

	#Ifdef __DEBUG__
	Line (xpos,ypos)-(this.posx, this.posy), rgb(0,255,0)
	#Endif

	Return sqr((a^2) + (b^2))
End Function

Function sprite.touching ( ByRef object As Sprite ) As Integer
	If ( this.distanceTo(object) < this.frame_size ) then
		#Ifdef __DEBUG__
		circle (this.posx, this.posy), this.frame_size/2, rgb(255,255,0)
		#Endif

		Return 1
	Else
		#Ifdef __DEBUG__
		circle (this.posx, this.posy), this.frame_size/2, rgb(255,0,0)
		#Endif

		Return 0
	Endif
End Function

'' args are: file path, image width, frame size, number of animations, delay per frame (ms)
Function sprite.load( ByVal path As String, ByVal w As Integer, ByVal h As Integer, _
		ByVal animations As Integer = 1, ByVal frame_delay As Integer = 100 ) As Integer

	If buffer <> 0 Then
		ImageDestroy(this.buffer)
		this.buffer = 0
	Endif

	this.buffer = imagecreate(w, h*animations)

	LoaDimageFile(path, this.buffer)

	If buffer = 0 then
		Return 0
	Endif

	this.animations = animations

	this.frame_size = h
	this.frame_total = (this.buffer->width/this.frame_size)-1

	this.frame_delay = frame_delay

	' set the center point to a default value
	this.refx = this.frame_size/2
	this.refy = this.frame_size/2

	#Ifdef __DEBUG__
	this.uuid = __spriteUUIDTotal
	__spriteUUIDTotal += 1
	#Endif

	Return 1
End Function

Function sprite.update() As Integer
	' Set sane defaults
	If this.scale < 1 then
		this.scale = 1
	Endif

	' Initial setup
	Dim As fb.Image Ptr output_buffer = ImageCreate ( this.frame_size*this.scale, this.frame_size*this.scale )
	Dim As Integer frame_offset = this.frame_size*this.frame_index
	Dim As Integer frame_x, frame_y

	' Calculate the components of the sprites velocity
	Dim As Integer Vx, Vy

	Vx = this.speed * cos(this.direction * __PI__ / 180)
	Vy = this.speed * sin(this.direction * __PI__ / 180)

	' Frame position in the source image
	If frame_offset > this.frame_size*this.frame_total then
		frame_offset = 0
	Endif

	' Default to the first frame If animate is non true
	If animate = 0 then
		frame_offset = 0
	Endif

	' set frame x and y pixel coords
	frame_x = frame_offset
	frame_y = (this.animate-1)*this.frame_size

	If frame_y < 0 Then:frame_y = 0:Endif

	' Handles advancing the animation
	If animate and ( ( timer*1000-this.lAst_draw ) > this.frame_delay ) then
		__int_framerefresh = 1

		' Move the sprite bAsed on the components of it's velocity
		this.posx += Vx
		this.posy += Vy

		' Advance the frame index
		this.frame_index += 1
		this.lAst_draw = timer*1000

		If this.frame_index > this.frame_total then
			this.frame_index = 0
		Endif
	Else
		__int_framerefresh = 0
	Endif

	' Handles the transFormations
	' For simplicity and perFormance reAsons only one is active at a time
	If this.flip_x then
		' Horozontal Flip
		For i As Integer = 0 to output_buffer->width
			put output_buffer, (i,0), this.buffer, (frame_x + this.frame_size - i, frame_y)-step(1, this.frame_size), PSET
		Next
	ElseIf this.flip_y then
		' Vertical Flip
		For i As Integer = 0 to output_buffer->width
			put output_buffer, (0, i), this.buffer, (frame_x, frame_y + this.frame_size - i)-step(this.frame_size, 1), PSET
		Next
	Else
		' No transForm
		put output_buffer, ( 0, 0 ), this.buffer, (frame_x, frame_y)-step(this.frame_size, this.frame_size), PSET
	Endif

	' Scaling
	If this.scale > 1 then
		Dim As UInteger c

		For x As Integer = 0 to this.frame_size
			For y As Integer = 0 to this.frame_size
			c = point(x+frame_x, y+frame_y, this.buffer)

			Line output_buffer, (x*this.scale, y*this.scale)-step(this.scale, this.scale), c, BF
			Next
		Next
	Endif

	' rotation
	If this.rotation then
	' Rotation
	' The input to the Function is radians
	rotate(this.frame_size*this.scale, this.frame_size*this.scale, (this.rotation/360)*2*__PI__, output_buffer)
	Endif

	' Finally draws the output buffer
	backbox()

	Put ( this.posx-this.refx*this.scale, this.posy-this.refy*this.scale ), _
	output_buffer, (0,0)-step(this.frame_size*this.scale, this.frame_size*this.scale), TRANS

	' Draws debug inFormation about the sprite If the executable wAs compiled with debugging
	spriteDebug("I: " & this.uuid & " F: " & this.frame_index & " Vx: " & Vx & " Vy: " & Vy & " R: " & this.rotation)

	' Free the output buffer
	imageDestroy(output_buffer)

	Return 0
End Function

Sub rotate(ByVal maxx As Double, _
	ByVal maxy As Double, _
	ByVal angle As Double, ByVal buf As Any Ptr)

	' Initialise stuff
	Dim As Double c=cos(angle)
	Dim As Double s=sin(angle)
	Dim As uinteger col

	' Temporary image buffer
	Dim tmp As Any Ptr = imagecreate(maxx, maxy)

	' These were initially pAssed As arguments but For my needs are supposed to be
	' Fixed values
	Dim As Double minx, miny
	Dim As Double sx = maxx/2, sy = maxy/2

	For y As integer= 0 to maxy
		' Complex multiply? Someone smarter than me wrote this
		Dim As Double srcx = (minx-sx) * c + (y   -sy) * s + sx
		Dim As Double srcy = (y   -sy) * c - (minx-sx) * s + sy
		For x As integer = 0 to maxx
			' Check If the source inFormation is within the bounds of the old image
			If srcx>=0 and srcx<=maxx and _
			srcy>=0 and srcy<=maxy then
			' Get the colour this pixel should be from the old image
			col=point(srcx,srcy, buf)
			Else
			' Otherwise make it transparent
			col=rgba(255,0,255,0)
			End If

			' Set the corresponding output pixel
			pset tmp, (x, y), col

			 ' ??
			srcx += c
			srcy -= s
		Next
	Next

	Put buf, (0,0), tmp, PSET
	imagedestroy(tmp)
End Sub
