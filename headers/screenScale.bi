'' Scale the screen content, so that we can have "bigger" graphics and use less
'' disk space (and less memory holding the bigger graphics, but this also uses some memory.)

'' Found this on the forum, it is a LOT faster than using Point()
#ifndef getPixelAddress
    #define getPixelAddress(img,col,row) cast(any ptr,img) + _
        sizeof(FB.IMAGE) + (img)->pitch * (row) + (img)->bpp * (col)
#endif

'' This function is literally just for scaling the screen (Not individiual buffers)
Sub scaleScreen()
	'' Compiling with scale < 2 will omit this code and remove any performance hit
	#ifdef __SCALE
	#if __SCALE > 1
	
	'' Static so we don't have to re-allocate memory constantly
	Static As fb.Image Ptr	screenBuffer
	Static As fb.Image Ptr	readBuffer
	
	Dim As Integer		pixel
	Dim As Integer		mash = 1
	
	' Allocate the buffers if they don't exist
	' Using static means the memory is only allocated once
	If screenBuffer = 0 Then
		screenBuffer = ImageCreate(__XRES, __YRES)
	Endif
	If readBuffer = 0 Then
		readBuffer = ImageCreate(__XRES/__SCALE, __YRES/__SCALE) 
	Endif
	
	' Get the screen contents, if we try to use ScreenPtr it seems to segfault so I am being safe here
	Get (0,0)-((__XRES/__SCALE)-1, (__YRES/__SCALE)-1), readBuffer
	
	For y As Integer = 0 to (__YRES/__SCALE)-1 Step mash
		For x As Integer = 0 to (__XRES/__SCALE)-1 Step mash
			' Read pixel memory directly
			pixel = *CPtr(Integer Ptr, getPixelAddress( readBuffer, x, y ))			
			
			' Draw the pixel but bigger
			Line screenBuffer, ( x*__SCALE, y*__SCALE)-STEP(__SCALE*mash, __SCALE*mash), pixel, BF
		Next
	Next
	
	Put (0,0), screenBuffer, PSET
	#endif
	#endif
End Sub

