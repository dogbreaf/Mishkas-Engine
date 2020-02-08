'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Display text and menus to the player
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Static Shared As Integer	textSpeed = 10

#macro stashScreen( a )
	Dim As fb.Image Ptr a = ImageCreate( __XRES, __YRES )
	Get (0,0)-(__XRES-1, __YRES-1), a
#endMacro
#macro restoreScreen( a )
	Put (0,0), a, PSET
	ImageDestroy(thisScreen):a = 0
#endMacro

'' Name all of our colors
enum textColors
	ansi_black = 30
	ansi_red
	ansi_green
	ansi_yellow
	ansi_blue
	ansi_magenta
	ansi_cyan
	ansi_white
	
	ansi_b_black = 90
	ansi_b_red
	ansi_b_green
	ansi_b_yellow
	ansi_b_blue
	ansi_b_magenta
	ansi_b_cyan
	ansi_b_white
end enum

'' convert color names to values
Function ansiColor( ByVal code As Integer ) As uInteger
	Select Case code
	
	Case ansi_black
		Return rgb(0,0,0)
	Case ansi_red
		Return rgb(170,0,0)
	Case ansi_green
		Return rgb(0,170,0)
	Case ansi_yellow
		Return rgb(170,85,0)
	Case ansi_blue
		Return rgb(0,0,170)
	Case ansi_magenta
		Return rgb(170,0,170)
	Case ansi_cyan
		Return rgb(0,170,170)
	Case ansi_white
		Return rgb(170,170,170)
	
	Case ansi_b_black
		Return rgb(85,85,85)
	Case ansi_b_red
		Return rgb(255,85,85)
	Case ansi_b_green
		Return rgb(85,255,85)
	Case ansi_b_yellow
		Return rgb(255,255,85)
	Case ansi_b_blue
		Return rgb(85,85,255)
	Case ansi_b_magenta
		Return rgb(255,85,255)
	Case ansi_b_cyan
		Return rgb(85,255,255)
	Case ansi_b_white
		Return rgb(255,255,255)
	
	End Select
	
	Return 0
End Function
'' Draw the box uesd as a background
Sub menuBox( ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer )
	Line (x,y)-STEP(w,h), rgb(255,255,255), BF
	Line (x+2,y+2)-STEP(w-4,h-4), rgb(0,0,0), B
	Line (x+4,y+4)-STEP(w-8,h-8), rgb(0,0,0), B
End Sub

'' Format a text string and draw it
Sub c_drawText( ByVal text As String, _
		ByVal x As Integer, ByVal y As Integer, _
		ByVal w As Integer = 80, _
		ByVal speed As Integer = 0, _
		ByVal style As textStyle = S_NONE )
		
	'' Cursor position
	Dim As Integer	curX
	Dim As Integer	curY
	
	Dim As String	char
	
	Dim As Boolean	escaped, underline
	
	Dim As Integer 	colour = textColors.ansi_black
	
	For i As integer = 0 to len(text)
		char = chr( text[i] )
		
		Select Case char
		
		Case chr(10)
			CurY += 1
			CurX = 0
			
		Case chr(254)
			Dim As String ansiCode
                		
			Do Until (char = " ") or (i = len(text)-1)
				i += 1
				
				char = chr(text[i])
				
				ansiCode += char
			Loop
			
			colour = val(ansiCode)
		
		Case chr(13)
			''
			
		Case Else
			drawString(x + (curX*8), y + (curY*10), char, ansiColor(colour), style)
			
			If underline Then
				Line (x+(curX*8), y + (curY*10) + 8 )-STEP(8,0), rgb(0,0,0)
			Endif
			
			curX += 1
		End Select
		
		If speed > 0 Then
			' Play any loaded sfx
			DialogueSound()
			
			' draw the text slowly
			Sleep speed,1
		Endif
		
		If curX > w Then
			curY += 1
			curX = 0
		Endif
	Next
End Sub

'' Wait for the user to press "E"
Sub waitNext( ByVal posX As Integer = 0, ByVal posY As Integer = 0 )	
	If posX and posY Then
		drawString(posX - 64, posY, "Press " & _KEY_ACTION & " " & Chr(31), rgb(0,0,0))
	Endif
	
	Do
		Sleep 10,1
	Loop Until getUserKey(kbd_Action, true)
End Sub

'' Transitions
enum transitionType
	tFade
	tBlinds
end enum

Sub transition( ByVal style As transitionType ) 
	Select Case style
	
	Case tFade
		'' fade to black
		Dim As fb.Image Ptr	fade = imageCreate( __XRES, __YRES, rgba(0,0,0,10) )
		
		For i As Integer = 0 to 30
			Put (0,0), fade, ALPHA
			Sleep 20,1
		Next
		
	Case tBlinds
		'' Blinds effect
		Dim As Integer nBlinds = 10
		Dim As Integer height = __XRES/nBlinds
		
		For i As Integer = 0 to height
			For j As Integer = 0 to nBlinds
				Line (0,(j*height)+i)-STEP(__XRES, 0), rgb(0,0,0)
			Next
			
			Sleep 20,1
		Next
		
	End Select
	
	Line (0,0)-(__XRES, __YRES), rgb(0,0,0), BF
End Sub

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Type _option
	text	As String
	label	As String
End Type

Function SelectMenu( options(Any) As _option, ByVal x As Integer = -1, ByVal y As Integer = -1, ByVal w As Integer = 256 ) As String
	Dim As Integer	optionCount = UBound( options )

	Dim As Integer	boxWidth = w
	Dim As Integer	boxHeight = ( optionCount*10 ) + 26
	
	Dim As Integer	posX = x
	Dim As Integer	posY = y
	
	Dim As Integer	selection
	
	stashScreen(thisScreen)
	
	'' Center the menu by default
	If x = -1 Then
		x = (__XRES/2)-(boxWidth/2)
	Endif
	If y = -1 Then
		y = (__YRES/2)-(boxHeight/2)
	Endif
	
	'' Let the user pick 
	Do
		ScreenLock
		menuBox( posX, posY, boxWidth, boxHeight )
			
		For i As Integer = 0 to optionCount			
			If i = selection then
				Line ( posX + 8, (posY + 8) + ( i*10 ) )-STEP( boxWidth-16, 10), rgb(0,0,0), BF
				
				'Draw String ( posX + 10, (posY + 10) + ( i*10 ) ), options(i).text, rgb(255,255,255)
				drawString(posX + 10, (posY + 10) + ( i*10 ), options(i).text, rgb(255,255,255))
			Else	
				'Draw String ( posX + 10, (posY + 10) + ( i*10 ) ), options(i).text, rgb(0,0,0)
				drawString(posX + 10, (posY + 10) + ( i*10 ), options(i).text, rgb(0,0,0))
			Endif
		Next
		
		drawButtonPrompt(_KEY_UP & "/" & _KEY_DN & " Select, " & _KEY_ACTION & " Confirm")
		ScreenUnLock
	
		If getUserKey(kbd_Up, false, 200) Then
			selection -= 1
			
		Elseif getUserKey(kbd_Down, false, 200) Then
			selection += 1
			
		Elseif getUserKey(kbd_Action, true) Then
			Return options(selection).label
			
		Endif
		
		If selection < 0 Then
			selection = 0
		Elseif selection > optionCount Then
			selection = optionCount
		Endif
		
		Sleep 1,1
	Loop Until GetUserKey(kbd_Quit, true)
	
	restoreScreen(thisScreen)
	
	Return ""
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Sub dialouge( ByVal text As String, ByVal confirmBtn As Boolean = true, ByVal bigMode As Boolean = false )
	Dim As Integer	boxWidth = IIF(__XRES < 512, __XRES-32, 512)
	Dim As Integer	boxHeight = 128
	
	Dim As Integer	posX = (__XRES/2)-(boxWidth/2) 
	Dim As Integer	posY = __YRES - (boxHeight + IIF(__XRES < 512, 16, 64))
	
	stashScreen(thisScreen)
	
	If bigMode Then
		boxWidth = __XRES-64
		boxHeight = __YRES - 256
		
		posX = (__XRES/2)-(boxWidth/2) 
		posY = 32
	Endif
	
	menuBox( posX, posY, boxWidth, boxHeight )
	c_drawText( text, posX + 16, posY + 16, (boxWidth/8)-4, textSpeed )
	
	If confirmBtn Then
		waitNext( posX + boxWidth - 24, posY + boxHeight - 20 )
		
		menuBox( posX, posY, boxWidth, boxHeight )
		Sleep 100,1
		
		'' Restore the screen when the user confirms
		'' If the user doesnt need to confirm then the dialouge is supposed to hang around
		restoreScreen(thisScreen)
	Endif
	
	If thisScreen <> 0 Then
		ImageDestroy(thisScreen)
		thisScreen = 0
	Endif
End Sub

Function confirm( ByVal gotoLabel As String, ByVal message As String = "" ) As String
	Dim As _option		yesNo(1)
	
	Dim As Integer		boxWidth = 48
	Dim As Integer		boxHeight = 40
	
	'' Should be positioned correctly for the dialouge box
	Dim As Integer		posX = (__XRES/2) + (IIF(__XRES < 512, (__XRES-32)/2, 256)-boxWidth) 
	Dim As Integer		posY = (__YRES-IIF(__XRES < 512, 128, 192)) - (boxHeight+20)
	
	Dim As String		ret
	
	yesNo(0).text = "Yes"
	yesNo(0).label = gotoLabel
	yesNo(1).text = "No"
	yesNo(1).label = ""
	
	stashScreen(thisScreen)
	
	'' Show the correct text underneath
	If message <> "" Then
		Dialouge( message, false )
	Endif
	
	'' Get the selection
	ret = selectmenu( yesNo(), posX, posY, boxWidth )
	
	'' Redraw the screen without the option dialouge
	restoreScreen(thisScreen)
	
	Return ret
End Function

Function getNumberAmount( ByVal minimum As Integer, ByVal maximum As Integer ) As Integer
	'' Pick a number amount
	Dim As Integer ret
	
	Dim As Integer		boxWidth = 60
	Dim As Integer		boxHeight = 45
	
	'' Should be positioned correctly for the dialouge box
	Dim As Integer		posX = (__XRES/2) + (IIF(__XRES < 512, (__XRES-32)/2, 256)-boxWidth) 
	Dim As Integer		posY = (__YRES-IIF(__XRES < 512, 128, 192)) - (boxHeight+20)
	
	stashScreen(thisScreen)
	
	Do
		ScreenLock
		menuBox( posX, posY, boxWidth, boxHeight )
		
		drawString(posX + (boxWidth/2) - 4, posY+8, chr(30), rgb(0,0,0))
		drawString(posX + (boxWidth/2) - 4, posY+boxHeight-12, chr(31), rgb(0,0,0))
		
		drawString(posX + (boxWidth/2) - (len(str(ret))*4), posY + (boxHeight/2)-4, str(ret), rgb(0,0,0))
		
		drawButtonPrompt(_KEY_UP & "/" & _KEY_DN & " Select " & _KEY_ACTION & " Confirm")
		ScreenUnLock
		
		If getUserKey(kbd_Up, false, 150) Then
			ret += 1
		ElseIf getUserKey(kbd_Down, false, 150) Then
			ret -= 1
		ElseIf getUserKey(kbd_Action, true) Then
			Exit Do
		ElseIf getUserKey(kbd_Quit, true) Then
			ret = 0
			Exit Do
		Endif
		
		If ret < minimum Then
			ret = maximum
		ElseIf ret > maximum Then
			ret = minimum
		Endif
		
		Sleep regulateFPS(60),1
	Loop
	
	restoreScreen(thisScreen)
	
	Return ret
End Function

Function getUserString( ByVal prompt As String = "?", ByVal maxLen As Integer = -1 ) As String
	'' get a string from the user
	Dim As String		ret
	Dim As Integer		maxLength = maxLen
	Dim As String		char

	Dim As Integer		boxWidth = __XRES/2
	Dim As Integer		boxHeight = 96
	
	Dim As Integer		posX = (__XRES/2)-(boxWidth/2)
	Dim As Integer		posY = (__YRES/2)-(boxHeight/2)
	
	If maxLen = -1 Then
		maxLength = (boxWidth-64)/8
	Endif
	
	stashScreen(thisScreen)
	
	Do:Sleep 1,1:Loop Until InKey() = ""
	
	Do
		ScreenLock
			Put (0,0), thisScreen, PSET
			
			menuBox(posX, posY, boxWidth, boxHeight)
			c_drawText(prompt, posX+32, posY+32, (boxWidth-64)/8)
			c_drawText(ret & "_", posX+32, posY+42, maxLength)
			
			c_drawText("Press Enter " & chr(31), posX+boxWidth-136, posY+boxHeight-32)
		ScreenUnLock
		
		char = InKey()
		
		If asc(char) > 31 and asc(char) < 128 Then
			ret += char
			
			If len(ret) > maxLength Then
				ret = Left(ret, maxLength)
			Endif
		ElseIf char = chr(8) Then
			ret = Left(ret, len(ret)-1)
		Endif
		
		If getUserKey(kbd_Quit) Then
			ret = ""
			
			Exit Do
		ElseIf Multikey(fb.SC_ENTER) Then
			Do:Sleep 10,1:Loop Until not Multikey(fb.SC_ENTER)
			Sleep 100,1
			
			Exit Do
		Endif
		
		Sleep regulateFPS(60),1
	Loop
	
	restoreScreen(thisScreen)
	
	Return ret
End Function

''''''''''''''''''''''''''''''''''''''''''''''''
Type userChooser
	options(Any)	As _option
	
	Declare Sub AddOption( ByVal As String, ByVal As String )
	Declare Function chooseOption( ByVal message As String, ByVal bottom As Boolean = false ) As String
End Type

Sub userChooser.AddOption( ByVal optionName As String, ByVal jumpLabel As String )
	Dim As Integer count = UBound(options)+1
	
	ReDim Preserve options(count) As _option
	
	options(count).text = optionName
	options(count).label = jumpLabel
End Sub

Function userChooser.chooseOption( ByVal message As String, ByVal bottom As Boolean = false ) As String
	Dim As Integer		boxWidth = __XRES/6
	Dim As Integer		boxHeight = __YRES/2
	
	Dim As Integer		posX = (__XRES/2) + (IIF(__XRES < 512, (__XRES-32)/2, 256)-boxWidth) 
	Dim As Integer		posY = (__YRES-IIF(__XRES < 512, 128, 192)) - (boxHeight+20)
	
	Dim As String		ret
	
	stashScreen(thisScreen)
	
	If bottom Then
		boxWidth = __XRES-64
		boxHeight = 128
		
		posX = 32
		posY = __YRES - (boxHeight + IIF(__XRES < 512, 16, 64))
	Endif
	
	'' Show the correct text underneath
	If message <> "" Then
		Dialouge( message, false )
	Endif
	
	'' Get the selection
	ret = selectmenu( options(), posX, posY, boxWidth )
	
	restoreScreen(thisScreen)
	
	'' Reset the options
	ReDim options(-1) As _option
	
	Return ret
End Function

