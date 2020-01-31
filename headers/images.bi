'' Abstraction of image loading ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Function LoadImageFile( ByVal FileName As String, ByVal img As Any Ptr ) As Integer
	BLoad FileName, img
	
	Return 1
End Function

