'' Draw Text in different styles ''''''''''''''''''''''''''''''''''''''''''''''
Enum textStyle
	s_none
	s_outline
	s_shadow
End Enum

'' Custom blending function for custom fonts with any color
Function blendText( ByVal src_color As UInteger, ByVal dest_color As UInteger, ByVal font_color As Any Ptr ) As UInteger
	' If it is transparent then don't draw anything, otherwise draw in the desired color
	If src_color = rgb(255,0,255) Then
		Return dest_color
	Else
		Return *CPtr(UInteger Ptr, font_color)
	Endif
End Function

'' Draw the text
Sub drawString( ByVal x As Integer, ByVal y As Integer, _
	ByVal text As String, _
	ByVal colour As UInteger = rgb(0,0,0), _
	ByVal style As textStyle = s_none, _
	ByVal fontToLoad As String = "" )
	
	Static As Any Ptr		font
	Static As String		fontName
	
	'' Load any custom font as needed
	If fontToLoad = "DEFAULT" Then
		'' Reset to the default font
		If font <> 0 Then
			ImageDestroy(font)
			font = 0
		Endif
		fontName = ""
	ElseIf fontToLoad <> fontName Then
		debugPrint("Load new font '" & fontToLoad & "'")
		
		'' Load the new font
		If font <> 0 Then
			ImageDestroy(font)
			font = 0
		Endif
		
		'' Update the font name so we don't reload it all the time
		fontName = fontToLoad
		
		'' Create some image buffers
		font = ImageCreate(8*256,9)
		Dim As Any Ptr tmp_font = ImageCreate(8*256,8)
		
		'' Load the font and put it in the right place in the font buffer
		LoadImageFile(fontToLoad, tmp_font)
		Put font, (0,1), tmp_font, PSET
		ImageDestroy(tmp_font)
		tmp_font = 0
		
		'' Create a font header so the file doesnt need one
		Dim As UByte Ptr	p
		ImageInfo( font,,,,,p )
		
		p[0] = 0
		p[1] = 0
		p[2] = 255
		
		For i As Integer = 0 to 255
			'' I am only doing 8x8 pixel fonts at the moment
			p[3+i] = 8
		Next
		
		'' That should be it :3
		Put (0,0), font, PSET
	Endif
	
	'' If a style is specified, then draw the under-layer
	Select Case style
	
	Case s_outline
		'' Draw the outline
		
	Case s_shadow
		'' Draw a drop-shadow
		
	End Select
	
	'' Draw the text
	If font = 0 Then
		'' Draw with the built in font
		Draw String (x,y), text, colour
	Else
		'' Draw with a custom font
		Draw String (x,y), text,, font, CUSTOM, @blendText, @colour
	Endif
End Sub

