#include once "fbgfx.bi"

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
#ifdef _IMG_SUPPORT_
#include "FreeImage.bi"
#endif

Function LoadImageFile( ByVal FileName As String, ByVal img As Any Ptr ) As Integer
        #ifdef _IMG_SUPPORT_
                
	'' vars
	Dim As FREE_IMAGE_FORMAT	format
	Dim As FIBITMAP Ptr             temp_buffer1
	Dim As FIBITMAP Ptr	        temp_buffer2
	Dim As fb.Image Ptr		converted
	
	Dim As Integer			w,h
	Dim As Integer			source_pitch, target_pitch
	
	'' Get the format
	format = FreeImage_GetFileType( FileName, 0 )
	
	'' Check the format
	If format = FIF_UNKNOWN Then
		format = FreeImage_GetFIFFromFilename(filename)
	Endif
	If format = FIF_UNKNOWN Then
		Return 0
	Endif
	
	'' Load the image data and convert it to 32 bit
	temp_buffer1 = FreeImage_Load( format, FileName, JPEG_ACCURATE )
	If temp_buffer1 = 0 Then
		Return 0
	Endif
	
	temp_buffer2 = FreeImage_ConvertTo32bits(temp_buffer1)
	
	'' Convert it to an FB.image ptr
	w = FreeImage_GetWidth( temp_buffer2 )
	h = FreeImage_GetHeight( temp_buffer2 )
	converted = ImageCreate(w,h)
	
	source_pitch = FreeImage_GetPitch( temp_buffer2 )
	target_pitch = converted->pitch
	
	FreeImage_FlipVertical( temp_buffer2 )
	
	Dim As Byte Ptr		target = CPtr(Byte Ptr, converted+1)
	Dim As Any Ptr		source = FreeImage_GetBits( temp_buffer2 )
	
	w *= 4
	For y As Integer = 0 to h - 1
		memcpy( target + (y * target_pitch), _
		        source + (y * source_pitch), _
		        w )
	Next
	
	'' Put the converted image in the new buffer
	Put img, (0,0), converted, PSET
	
	'' Clean up
	ImageDestroy(converted)
	FreeImage_Unload(temp_buffer1)
	FreeImage_Unload(temp_buffer2)

	Return 1
        
        #else
        BLoad FileName, Img
        
        Return 1
        #endif
End Function


