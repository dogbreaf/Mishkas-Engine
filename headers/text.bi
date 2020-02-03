'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' Display text and menus to the player
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Static Shared As Integer	textSpeed = 10

'' Draw the box uesd as a background
Sub menuBox( ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer )
	Line (x,y)-STEP(w,h), rgb(255,255,255), BF
	Line (x+2,y+2)-STEP(w-4,h-4), rgb(0,0,0), B
	Line (x+4,y+4)-STEP(w-8,h-8), rgb(0,0,0), B
End Sub

'' Format a text string and draw it
Sub drawText( ByVal text As String, ByVal x As Integer, ByVal y As Integer, ByVal w As Integer = 80, ByVal speed As Integer = 0 )
	'' Cursor position
	Dim As Integer	curX
	Dim As Integer	curY
	
	Dim As String	char
	
	Dim As Boolean	escaped, underline
	
	For i As integer = 0 to len(text)
		char = chr( text[i] )
		
		Select Case char
		
		Case chr(10)
			CurY += 1
			CurX = 0
		
		Case chr(13)
			''
			
		Case Else
			Draw String ( x + (curX*8), y + (curY*10) ), char, rgb(0,0,0)
			
			If underline Then
				Line (x+(curX*8), y + (curY*10) + 8 )-STEP(8,0), rgb(0,0,0)
			Endif
			
			curX += 1
		End Select
		
		If speed > 0 Then
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
		Draw String ( posX - 64, posY ), "Press E " & Chr(31), rgb(0,0,0)
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
				
				Draw String ( posX + 10, (posY + 10) + ( i*10 ) ), options(i).text, rgb(255,255,255)
			Else	
				Draw String ( posX + 10, (posY + 10) + ( i*10 ) ), options(i).text, rgb(0,0,0)
			Endif
		Next
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
	
	Return ""
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Sub dialouge( ByVal text As String, ByVal confirmBtn As Boolean = true )
	Dim As fb.Image Ptr thisScreen
	
	Dim As Integer	boxWidth = IIF(__XRES < 512, __XRES-32, 512)
	Dim As Integer	boxHeight = 128
	
	Dim As Integer	posX = (__XRES/2)-(boxWidth/2) 
	Dim As Integer	posY = __YRES - (boxHeight + IIF(__XRES < 512, 16, 64))
	
	thisScreen = imageCreate( __XRES, __YRES )
	Get (0,0)-(__XRES-1,__YRES-1), thisScreen
	
	menuBox( posX, posY, boxWidth, boxHeight )
	drawText( text, posX + 16, posY + 16, (boxWidth/8)-4, textSpeed )
	
	If confirmBtn Then
		waitNext( posX + boxWidth - 24, posY + boxHeight - 20 )
		
		menuBox( posX, posY, boxWidth, boxHeight )
		Sleep 100,1
		
		'' Restore the screen when the user confirms
		'' If the user doesnt need to confirm then the dialouge is supposed to hang around
		Put (0,0), thisScreen, PSET
	Endif
	
	ImageDestroy(thisScreen)
End Sub

'' Large full screen box of text
Sub bigDialouge( ByVal text As String, ByVal confirmBtn As Boolean = true )
	Dim As Integer	boxWidth = __XRES-64
	Dim As Integer	boxHeight = __YRES - 256
	
	Dim As Integer	posX = (__XRES/2)-(boxWidth/2) 
	Dim As Integer	posY = 32
	
	menuBox( posX, posY, boxWidth, boxHeight )
	drawText( text, posX + 16, posY + 16, (boxWidth/8)-4, textSpeed )
	
	If confirmBtn Then
		waitNext( posX + boxWidth - 24, posY + boxHeight - 20 )
		
		menuBox( posX, posY, boxWidth, boxHeight )
		Sleep 100,1
	Endif
End Sub

Function confirm( ByVal gotoLabel As String, ByVal message As String = "" ) As String
	Dim As fb.Image Ptr	thisScreen
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
	
	'' Save what is on the screen so when the menu closes we can redraw the area under it
	thisScreen = imageCreate( __XRES, __YRES )
	Get (0,0)-(__XRES-1,__YRES-1), thisScreen
	
	'' Show the correct text underneath
	If message <> "" Then
		Dialouge( message, false )
	Endif
	
	'' Get the selection
	ret = selectmenu( yesNo(), posX, posY, boxWidth )
	
	'' Redraw the screen without the option dialouge
	Put (0,0), thisScreen, PSET
	ImageDestroy(thisScreen)
	
	Return ret
End Function

Function getNumberAmount( ByVal minimum As Integer, ByVal maximum As Integer ) As Integer
	'' Pick a number amount
	Dim As Integer ret
	
	Dim As fb.Image Ptr	thisScreen
	
	Dim As Integer		boxWidth = 60
	Dim As Integer		boxHeight = 45
	
	'' Should be positioned correctly for the dialouge box
	Dim As Integer		posX = (__XRES/2) + (IIF(__XRES < 512, (__XRES-32)/2, 256)-boxWidth) 
	Dim As Integer		posY = (__YRES-IIF(__XRES < 512, 128, 192)) - (boxHeight+20)
	
	thisScreen = imageCreate( __XRES, __YRES )
	Get (0,0)-(__XRES-1,__YRES-1), thisScreen
	
	Do
		ScreenLock
		menuBox( posX, posY, boxWidth, boxHeight )
		Draw String (posX + (boxWidth/2) - 4, posY+8), chr(30), rgb(0,0,0)
		Draw String (posX + (boxWidth/2) - 4, posY+boxHeight-12), chr(31), rgb(0,0,0)
		
		Draw String (posX + (boxWidth/2) - (len(str(ret))*4), posY + (boxHeight/2)-4), str(ret), rgb(0,0,0)
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
	
	Put (0,0), thisScreen, PSET
	ImageDestroy(thisScreen)
	
	Return ret
End Function

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
	Dim As fb.Image Ptr	thisScreen
	
	Dim As Integer		boxWidth = __XRES/6
	Dim As Integer		boxHeight = __YRES/2
	
	'' Should be positioned correctly for the dialouge box
	Dim As Integer		posX = (__XRES/2) + (IIF(__XRES < 512, (__XRES-32)/2, 256)-boxWidth) 
	Dim As Integer		posY = (__YRES-IIF(__XRES < 512, 128, 192)) - (boxHeight+20)
	
	If bottom Then
		boxWidth = __XRES-64
		boxHeight = 128
		
		posX = 32
		posY = __YRES - (boxHeight + IIF(__XRES < 512, 16, 64))
	Endif
	
	Dim As String		ret
	
	'' Save what is on the screen so when the menu closes we can redraw the area under it
	thisScreen = imageCreate( __XRES, __YRES )
	Get (0,0)-(__XRES-1,__YRES-1), thisScreen
	
	'' Show the correct text underneath
	If message <> "" Then
		Dialouge( message, false )
	Endif
	
	'' Get the selection
	ret = selectmenu( options(), posX, posY, boxWidth )
	
	'' Redraw the screen without the option dialouge
	Put (0,0), thisScreen, PSET
	ImageDestroy(thisScreen)
	
	'' Reset the options
	ReDim options(-1) As _option
	
	Return ret
End Function

