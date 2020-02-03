'' Unashamedly stolen from the forum 
Function RegulateFPS(Byval MyFps As Long,Byref fps As Long=0) As Long
	Static As Double timervalue,_lastsleeptime,t3,frames
	frames+=1
	If (Timer-t3)>=1 Then t3=Timer:fps=frames:frames=0
	Var sleeptime=_lastsleeptime+((1/myfps)-Timer+timervalue)*1000
	If sleeptime<1 Then sleeptime=1
	_lastsleeptime=sleeptime
	timervalue=Timer
	Return sleeptime
End Function

'' My own framecounter
Sub FrameCounter( ByVal x As Integer, ByVal y As Integer )
	Dim As String		outputString
	
	Static As Double	prevTime
	Static As Double	frameTime
	
	frameTime = Timer - prevTime
	prevTime = Timer
	
	outputString = Cast(Integer, 1/frameTime) & " FPS  "
	
	Line ( x-1, y-1 )-STEP(Len(outputString)*8,10), rgb(0,0,0), BF
	Draw String ( x, y ), outputString, rgb(255,220,0)
End Sub

'' Abstraction of image loading ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Function LoadImageFile( ByVal FileName As String, ByVal img As Any Ptr ) As Integer
	BLoad FileName, img
	
	Return 1
End Function

