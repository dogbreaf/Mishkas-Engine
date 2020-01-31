'' Objects for NPCs etc.
Type gameObject Extends Sprite
	target_posX	As Integer
	target_posY	As Integer
	
	xPosition	As Integer
	yPosition	As Integer
	zPosition	As Integer = 2
	
	movespeed	As Integer = 4
	
	stoppedMoving	As Boolean
	moving		As Boolean
	wasMoving	As Boolean
	
	disabled	As Boolean
	animateDefault	As Boolean = false
	
	'' Triggers
	playerActionTrigger	As String
	playerTouchTrigger	As String
	
	movementDoneTrigger	As String
	
	Declare Sub updateMovement( ByVal As Integer = 0, ByVal As Integer = 0 )
	Declare Sub moveTo( ByVal As Integer, ByVal As Integer )
	Declare Sub setPos( ByVal As Integer, ByVal As Integer )
End Type

Sub gameObject.updateMovement( ByVal viewportX As Integer = 0, ByVal viewportY As Integer )
	'' Use default animation unless moving
	this.animate = animateDefault
	
	'' Detect movement ending	
	wasMoving = moving
	moving = false
	
	'' Decide on animation to use
	Dim As Integer walk_normal_anim = 1
	Dim As Integer walk_up_anim = 1
	Dim As Integer walk_dn_anim = 1
	
	If this.animations > 1 Then
		walk_up_anim = 2
		walk_dn_anim = 3
	Endif
	
	'' Move to target position
	If xPosition < target_posX Then
		this.animate = walk_normal_anim
		this.flip_x = 0
		If this.__int_framerefresh Then
			xPosition += movespeed
		Endif
		moving = true
	Elseif xPosition > target_posX Then
		this.animate = walk_normal_anim
		this.flip_x = 1
		If this.__int_framerefresh Then
			xPosition -= movespeed
		Endif
		moving = true
	Endif
	
	If yPosition < target_posY Then
		this.animate = walk_dn_anim
		If this.__int_framerefresh Then
			yPosition += movespeed
		Endif
		moving = true
	Elseif yPosition > target_posY Then
		this.animate = walk_up_anim
		If this.__int_framerefresh Then
			yPosition -= movespeed
		Endif
		moving = true
	Endif
	
	If wasMoving and (not moving) Then
		' Stopped moving
		stoppedMoving = true
	Else
		stoppedMoving = false
	Endif
		
	'' Set the drawing coords to match the viewport
	this.posx = xPosition-viewportX
	this.posy = yPosition-viewportY
End Sub

Sub gameObject.moveTo( ByVal x As Integer, ByVal y As Integer )
	this.target_posX = (x*32)+16
	this.target_posY = (y*32)+16
End Sub

Sub gameObject.setPos( ByVal x As Integer, ByVal y As Integer )
	this.xPosition = (x*32)+16
	this.yPosition = (y*32)+16
	
	this.target_posX = xPosition
	this.target_posY = yPosition
End Sub

