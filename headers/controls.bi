'' Possible keyboard inputs
enum inputAction
	kbd_Up
	kbd_Down
	kbd_Left
	kbd_Right
	
	kbd_Action
	kbd_Attack
	kbd_Quit
	kbd_Close
end enum

'' The key to display in prompts
#define _KEY_UP "W"
#define _KEY_DN "S"
#define _KEY_LF "A"
#define _KEY_RG "D"
#define _KEY_ACTION "E"
#define _KEY_QUIT "Esc"

'' Check keyboard input
Function getUserKey( ByVal action As inputAction, ByVal waitForKeyUp As Boolean = False, ByVal keyRepeat As Integer = 100 ) As Boolean
	Dim As Integer	Key1
	Dim As Integer	Key2
	
	Dim As Boolean	ret
	
	Select Case action
	
	'' Select the keys depending on the action
	'' ~~ KEYBIND SETTINGS ~~
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
		
	Case kbd_Attack
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
	
	'' ~~ END OF KEYBINDS ~~
	
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

'' Display a button prompt
Sub drawButtonPrompt( ByVal prompt As String )
	Dim As Integer posx, posy
	
	posx = __XRES - len(prompt)*8 - 60
	posy = __YRES - 20
	
	'' Draw the string
	'Draw String (posx, posy), prompt, rgb(255,255,255)
	drawString(posx,posy, prompt, rgb(255,255,255), s_outline)
End Sub

