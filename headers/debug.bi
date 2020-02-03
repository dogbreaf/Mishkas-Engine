'' Print debug messages to stderr '''''''''''''''''''''''''''''''''''''''''''''
Sub debugPrint( ByVal msg As String ) 
	Static As Integer	stdErr
	
	#ifdef __DEBUGGING__
	If stdErr = 0 Then
		stdErr = FreeFile
		Open Err For Output As #stdErr
	Endif
	
	Print #stdErr, msg
	#endif
End Sub

