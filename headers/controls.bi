enum inputAction
	kbd_Up
	kbd_Down
	kbd_Left
	kbd_Right
	
	kbd_Action
	kbd_Atack
	kbd_Quit
	kbd_Close
end enum

Function getUserKey( ByVal action As inputAction, ByVal waitForKeyUp As Boolean = False, ByVal keyRepeat As Integer = 100 ) As Boolean
	Dim As Integer	Key1
	Dim As Integer	Key2
	
	Dim As Boolean	ret
	
	Select Case action
	
	'' Select the keys depending on the action
	Case kbd_Up
		Key1 = fb.SC_UP
		Key2 = fb.SC_W
		
	Case kbd_Down
		Key1 = fb.SC_DOWN
		Key2 = fb.SC_S
		
	Case kbd_Left
		Key1 = fb.SC_LEFT
		Key2 = fb.SC_A
		
	Case kbd_Right
		Key1 = fb.SC_RIGHT
		Key2 = fb.SC_D
		
	Case kbd_Action
		Key1 = fb.SC_ENTER
		Key2 = fb.SC_E
		
	Case kbd_Atack
		Key1 = fb.SC_SPACE
		Key2 = -1
		
	Case kbd_Quit
		Key1 = fb.SC_ESCAPE
		Key2 = -1
		
	Case kbd_Close
		'' Check for close button
		If InKey() = Chr(255) & "k" Then
			Return true
		Else
			Return false
		Endif
	End Select
	
	'' Check if the key is pressed
	If Multikey(Key1) or IIF( Key2 = -1, 0, Multikey(Key2)) Then
		ret = true
		
		'' Prevent keys being repeated too quickly
		Sleep keyRepeat,1
	Endif
	
	'' Wait for keyUp to prevent key repeats 
	If waitForKeyUp and ret Then
		Do:Sleep 10,1:Loop Until (not Multikey(Key1)) and IIF(Key2 = -1, -1, not Multikey(Key2))
		Sleep keyRepeat,1
	Endif
	
	'' Return true/false
	Return ret
End Function

