''
'' Basic script interpreter for games?
''
'' By Mishka
''

#define __EXT_TRIMSET__ chr(9) & chr(32) & chr(0) & chr(10) & chr(13)

'' String utility functions
''

'' Splits a string into an array of words that were separated by
'' whitespace
Function strWords( ByVal inputTemp As String, outputString(any) As String ) As Integer
        Dim As Integer  wordIndex = 0
        Dim As String   char = " "
        Dim As String   prevChar
        Dim As Integer  maxWords = uBound(outputString)
        Dim As String   inputString
        
        Dim As Boolean  quote = false
        
        ' Shit fucks up if we run on an empty line
        inputString = trim(inputTemp, __EXT_TRIMSET__)
        
        If len(inputString) = 0 Then
                Return 0
        End If
        
        ' Search for words
        For i As Integer = 0 to len( inputString )
                prevChar = char
                char = chr( inputString[i] )
                
                If wordIndex > maxWords Then
                        ' Apparently re-sizing the array messes up the pointer
                        ' internally so we are limited to the initial size that
                        ' we were given 
                        return maxWords
                End If

                Select Case char
                
                Case chr(34)
                        quote = not quote
                        
                Case chr(32),chr(9)
                        If quote Then
                                outputString(wordIndex) += char
                        ElseIf ( prevChar <> chr(32) ) and _
                               ( prevChar <> chr(9) ) Then
                                
                                outputString(wordIndex) = trim(outputString(wordIndex), __EXT_TRIMSET__)
                                
                                wordIndex += 1
                        End If
                
                Case chr(13), chr(10), chr(0)
                        ' don't count newlines and junk for anything because reeeeeeeee
                        ' and apparently trim isnt removing this junk 
                
                Case Else
                        outputString(wordIndex) += char
                        
                End Select
        Next
        
        return wordIndex
End Function

'' Holds a var, typing is loose and all data is stored
'' as strings.
'' This could probably be changed to optimise for speed 
'' but I haven't decided how and I want loose typing.
type _var
        var_name        As String
        var_value       As String
end type

'' The stack holds variables
type _stack
        Private:
        varList(Any)  As _var
        
        Public:
        Declare Sub setVar Overload ( ByVal As String, ByVal As String )
        Declare Sub setVar ( ByVal As String, ByVal As Integer )
        
        Declare Function getVar ( ByVal As String ) As String
        
        Declare Function varPtr ( ByVal As String ) As String Ptr
        
        Declare Sub save( ByVal As String ) 
        Declare Sub load( ByVal As String )
end type

Sub _stack.setVar( ByVal _name As String, ByVal _value As String )
        ' Set a variable to a specific value. Typing is loose and non
        ' existing variables will be created as needed.
        Dim As Integer index = -1
        Dim As Integer listSize = UBound( this.varList )
        
        ' search for the variable's index (can this be optimized?)
        For i As Integer = 0 to listSize
                If this.varList(i).var_name = _name Then
                        ' This is the variable we need
                        index = i
                        Exit For
                End If
        Next
        
        ' Unlike a language I have forgotten I am pretty sure
        ' FreeBASIC doesn't have for...else
        If index = -1 Then
                ' Grow the varList
                index = listSize + 1
                ReDim Preserve this.varList(index) As _var
                
                ' Assign the name so we can find the var again
                this.varList(index).var_name = _name
        End If
        
        ' Actually assign the new value
        this.varList(index).var_value = _value
End Sub

Sub _stack.setVar( ByVal _name As String, ByVal _value As Integer )
        ' Overload version for using integers internally
       this.setVar( _name, str(_value) ) 
End Sub

Function _stack.getVar( ByVal _name As String ) As String        
        ' Get the value of a named variable
        Dim As Integer listSize = UBound( this.varList )
        
        For i As Integer = 0 to listSize
                If this.varList(i).var_name = _name Then
                        return this.varList(i).var_value
                End If
        Next
        
        Return ""
End Function

Function _stack.varPtr( ByVal _name As String ) As String Ptr
	Dim As Integer		listSize = UBound( this.varList )
	Dim As String Ptr	ret
	
	For i As Integer = 0 to listSize
		If this.varList(i).var_name = _name Then
			Return @this.varList(i).var_value
		End If
	Next
	
	Return ret
End Function

Sub _stack.Save( ByVal fileName As String )
        ' Save the stack to a file
        Dim As Integer	hndl = FreeFile
        Dim As Integer  listSize = UBound(this.varList)
	
	Open fileName For Output As #hndl
	
	Print #hndl, "// Auto save to '" & fileName & "'"
	
	for i As integer = 0 to listSize
		Print #hndl, _
                        chr(34) & this.varList(i).var_name & chr(34) & chr(32) & _
                        chr(34) & this.varList(i).var_value & chr(34)
	next
	
	Close #hndl
End Sub

Sub _stack.load( ByVal fileName As String )
        ' Save the stack to a file
        Dim As Integer	hndl = FreeFile
        Dim As Integer  listSize = UBound(this.varList)
        
        Dim As String   inputLine
	
	Open fileName For Input As #hndl
	
	Do
		Line Input #hndl, inputLine
                
                ' Don't waste time if this is a comment
                If left(inputLine, 2) <> "//" Then
                        Dim As String args(1)
                        
                        strWords(inputLine, args())
                        this.setVar( args(0), args(1) )
                End If
	Loop until eof(hndl)
	
	
	Close #hndl
End Sub

'' Handles the code execution
type script
        Private:
        code(Any,Any)   As String
        
        lineNumber      As Integer
        
        stderr          As Integer
        
        callBacks(Any)  As Function ( (Any) As String, As script Ptr ) As Integer
                
        Declare Sub addLine( (any) As String )
        
        Declare Function stringLiteral( ByVal As String ) As String
        
        Public:
        ' Run every time the parsing loop is run
        interimCallback	As Sub
        
        ' Public so that other code (like callbacks) can manipulate
        stack           As _stack
        
        ' methods
        Declare Sub load( ByVal As String )
        Declare Sub parseString( ByVal As String )
        
        Declare Sub execute()
        Declare Sub clear()
        
        Declare Sub seekTo( ByVal As String, ByVal As Boolean = false )
        Declare Sub sendError( ByVal As String, ByVal As Boolean = false )
        
        Declare Sub addOperator( As Function ( (any) As String, As script Ptr ) As Integer )
        
        Declare Sub dumpCode( ByVal As String )
        Declare Sub dumpStack( ByVal As String )
        
        Declare Function varPtr( ByVal As String ) As String Ptr
end type

Sub script.load( ByVal fileName As String )
        Dim As Integer  hndl = FreeFile
        Dim As String   inputLine
        Dim As String	code
        
        Open fileName for input as #hndl
        
        If stderr = 0 Then
                stderr = FreeFile
                Open Err For Output As #stderr
        End If
        
        Do
                Line Input #hndl, inputLine
                
                code += inputLine & chr(10)
        Loop Until eof(hndl)
        
        this.parseString( code )
        
        Close #hndl
End Sub

Sub script.execute()
        Dim As Integer lastLine = UBound(this.code, 1)
        Dim As Integer returnLine = 0
        
        Randomize Timer
        
        Do
                ' Temp var for the args
                Dim As String args(6)
                
                ' Substitute in the value of variables where needed
                For i As Integer = 0 to 6
                        args(i) = this.code(lineNumber,i)
                        
                        Dim As String Ptr currentWord = @args(i)
                        
                        ' if it is escaped in percent signs
                        ' is concatinating the results faster than individual comparson?
                        If Left(*currentWord,1) & Right(*currentWord,1) = "%%" Then
                                ' I think this is faster than going char by char
                                ' like we need to for string literals
                                *currentWord = this.stack.getVar( _
                                        mid(*currentWord, 2, len(*currentWord)-2) )
                                        
                        ' If this is a string literal (contains a space usually)
                        ElseIf inStr(*currentWord, " ") Then
                                *currentWord = this.stringLiteral(*currentWord)
                        End If
                Next
                
                ' Hopefully using select case makes this faster than last time
                Select Case args(0)
               
                Case "Print"
                        Print args(1)
                       
                Case "If"
                        ' Figure out which comparison to use
                        ' the actual program logic is the opposite of what is
                        ' written in the script because the positive action is
                        ' to skip ahead
                        Select Case args(2)
                        
                        Case "="
                                If args(1) <> args(3) Then
                                        this.seekTo("Endif")
                                End If
                        
                        Case "!="
                                If args(1) = args(3) Then
                                        this.seekTo("Endif")
                                End If
                                
                        Case ">"
                                If val( args(1) ) < val( args(3) ) Then
                                        this.seekTo("Endif")
                                End If
                        
                        Case "<"
                                If val( args(1) ) > val( args(3) ) Then
                                        this.seekTo("Endif")
                                End If
                                
                        Case Else
                                this.sendError("Unknown comparitor", true)
                        
                        End Select
                        
                Case "Set"
                        Dim As String varName = args(1)
                        Dim As String assignment = args(3)
                        
                        ' Check the assignment operator
                        Select Case args(2)
                        
                        Case "="
                                this.stack.setVar( varName, assignment )
                                
                        Case "+="
                        	Dim As String Ptr variable = this.stack.varPtr(varName)
                        	
                                Dim As Double oldValue = val(*variable)
                                Dim As Double assValue = val(assignment)
                                
                                *variable = str(oldValue + assValue)
                                
                        Case "-="
                                Dim As String Ptr variable = this.stack.varPtr(varName)
                        	
                                Dim As Double oldValue = val(*variable)
                                Dim As Double assValue = val(assignment)
                                
                                *variable = str(oldValue - assValue)
                                
                        Case "*="
                                Dim As String Ptr variable = this.stack.varPtr(varName)
                        	
                                Dim As Double oldValue = val(*variable)
                                Dim As Double assValue = val(assignment)
                                
                                *variable = str(oldValue * assValue)
                                
                        Case "/="
                                Dim As String Ptr variable = this.stack.varPtr(varName)
                        	
                                Dim As Double oldValue = val(*variable)
                                Dim As Double assValue = val(assignment)
                                
                                *variable = str(oldValue / assValue)
                        
                        End Select
                        
                Case "Random"
                        Dim As String varName = args(1)
                        Dim As Integer minVal = val(args(2))
                        Dim As Integer maxVal = val(args(3))
                        
                        this.stack.setVar( varName, (rnd()*(maxVal-minVal))+minVal )
                        
                Case "Goto"
                        Dim As String label = args(1)
                        this.seekTo(":" & label, true)
                        
                Case "GoSub"
                        ' Allows us to return to a previous point
                        Dim As String label = args(1)
                        
                        If returnLine Then
                                this.sendError("GoSub inside GoSub.", true)
                        Else
                                returnLine = lineNumber
                                this.seekTo(":" & label, true)
                        End If
                        
                Case "Return"
                        ' Return from a GoSub
                        If returnLine Then
                                ' skip one line so we don't infinite loop
                                lineNumber = returnLine+1
                                returnLine = 0
                        Else
                                this.sendError("Return without GoSub.", true)
                        End If
                        
                ' Debug functions
                Case "Dump"
                	this.dumpCode( args(1) )
                	
                Case "SaveStack"
                	this.stack.save( args(1) )
                	
                Case "LoadStack"
                	this.stack.load( args(1) )
                        
                Case "Sleep"
                        Sleep val( args(1) ),1
                        
                Case "Quit"
                        ' Pretty self explanitory 
                        End
                        
                Case "End"
                	Exit Do
                
                Case "Endif"
                        ' no need to do anything
                        
                Case Else
                        Dim As Integer numCallBacks = UBound(this.callBacks)
                        Dim As String  currentOperator = args(0)
                        Dim As Boolean found = false
                        
                        If ( numCallBacks > -1 ) and ( left(currentOperator, 1) <> ":" ) Then
                                For i As Integer = 0 to numCallBacks                                           
                                        found = this.callBacks(i)( args(), @this )  
                                        
                                        If found Then
                                        	Exit For
                                        Endif
                                Next
                                
                                If not found Then
                                        this.sendError("Unknown Operator, '" & currentOperator & "'")
                                End If
                        Else
                                If left(currentOperator, 1) = ":" Then
                                        ' this is a label we don't need to do anything
                                        ' we might add a lookup table for labels 
                                        ' to speed up goto and gosub maybe
                                Else
                                        this.sendError("Unknown Operator, '" & currentOperator & "'")
                                End If
                        End If
                End Select
                
                this.lineNumber += 1
                
                '' Run the interim callback
                If this.interimCallback Then
                	this.interimCallback()
                Endif
        Loop Until this.lineNumber > lastLine
End Sub

'' Clear all existing code
Sub script.clear()
	ReDim this.code(1,6) As String
	
	this.lineNumber = 0
End Sub

'' Parse a string instead of a file
Sub script.parseString( ByVal code As String ) 
        Dim As String   inputLine
        Dim As Integer  lineCount
        
        Dim As Integer	codePos
        Dim As String	char
        
        Dim As String tempLabel,iterator
        Dim As Integer fromNum,toNum
        
        If stderr = 0 Then
                stderr = FreeFile
                Open Err For Output As #stderr
        End If
        
        Do
        	inputLine = ""
        	
                Do
                	char = chr( code[codePos] )
                	codePos += 1
                	
                	If char = chr(9) Then
                		inputLine += chr(32)
                	Elseif asc(char) > 31 Then
                		inputLine += char
                	Endif
                Loop Until (codePos > len(code)) or (char = chr(10))
                
                If (left(inputLine, 2) <> "//") and (len(inputLine) > 0) Then                
                        Dim As String splitLine(6)      ' for splitting the line
                        Dim As Integer numberOfWords
                
                        numberOfWords = strWords(inputLine, splitLine())
                        
                        ' "Preprocessor" features
                        Select Case splitLine(0)
                        
                        Case "Include"
                                this.load( splitLine(1) )
                                
                        Case "For"
                        	' make a for statement into a pretty simple loop
                        	' this seems to be easier than actually implementing this seperately
                        	
                        	' collision will basically never happen, it should be too 
                        	' unlikley to even consider
                        	tempLabel = "__" & hex(rnd()*(2^32)) & hex(rnd()*(2^32)) & "__"
                        	
                        	iterator = splitLine(1)
                        	
                        	fromNum = val( splitLine(2) )
                        	toNum = val( splitLine(3) )
                        	
                        	' add the code we need                        	
                        	Dim As String insertCode(1,6) = { _
                				{"Set",iterator,"=", str(fromNum)}, _
                				{":" & tempLabel} _
                			}

				For i As Integer = 0 to 1
						For z As Integer = 0 to 6
							splitLine(z) = insertCode(i,z)
						Next
						
	                        		this.addLine(splitLine())
	                        	Next
                        	
                        Case "Next"
                        	If tempLabel = "" Then
                        		this.sendError("'Next' without 'For'", true)
                        	Else
                        		' add the end of the for loop code
                        		Dim As String insertCode(3,6) = { _
                        				{"Set", iterator, "+=", "1"}, _
                        				{"If", "%" & iterator & "%", "<", str(toNum)}, _
                        				{"Goto", tempLabel}, _
                        				{"Endif"} _
                        			}

					For i As Integer = 0 to 3
						For z As Integer = 0 to 6
							splitLine(z) = insertCode(i,z)
						Next
						
	                        		this.addLine(splitLine())
	                        	Next
	                        	
	                        	tempLabel = ""
	                        	iterator = ""
	                        	fromNum = 0
	                        	toNum = 0
                        	End If
                        	
                        Case Else
                                this.addLine(splitLine())
                                
                        End Select

                        lineCount += 1
                End If
        Loop Until codePos > len(code)
End Sub

'' add a custom operator
Sub script.addOperator( callBack As Function ( (any) As String, As script Ptr ) As Integer )
        Dim As Integer index = uBound( this.callBacks ) + 1
        
        ReDim Preserve this.callBacks(index) As Function ( (Any) As String, As script Ptr ) As Integer
        
        this.callBacks(index) = callBack
End Sub

'' Send an error message to stdErr
Sub script.sendError( ByVal msg As String, ByVal fatal As Boolean = false )
        Print #this.stderr, "Error on Line " & this.lineNumber & ": " & msg
        
        If fatal Then
                End
        End If
End Sub

'' Seek to the line of code that starts with a certain string
Sub script.seekTo( ByVal word As String, ByVal fromStart As Boolean = false )
        Dim As Integer lastLine = UBound(this.code,1)
        
        If fromStart Then
                this.lineNumber = 0
        Else
                ' Don't bother checking the line of code we were on
                this.lineNumber += 1
        End If
        
        Do
                If this.code(lineNumber, 0) = word Then
                        return
                End If
                
                this.lineNumber += 1
        Loop Until this.lineNumber = lastLine
        
        this.sendError("Expected '" & word & "', found end of file.", true)
End Sub

'' Add an array of strings as a line of code
Sub script.addLine( words(Any) As String )
        Dim As Integer lineIndex = UBound( this.code, 1 )+1
        Dim As Integer wordIndex = UBound( words )
        
        ReDim Preserve this.code( lineIndex, wordIndex ) As String
        
        For i As Integer = 0 to wordIndex
                this.code(lineIndex, i) = words(i)
        Next
End Sub

'' Substitute escaped variables etc. in a string literal
'' This can probably be optimised
Function script.stringLiteral( ByVal literal As String) As String
        Dim As String   ret
        Dim As Integer  length = len(literal)
        Dim As String   char
        Dim As String   prevChar
        
        Dim As String   varName
        
        Dim As Boolean	cleartext = true
        Dim As String	escapeChar
        
        For i As Integer = 0 to length
                prevChar = char
                char = chr(literal[i])
                
                If prevChar = "\" Then
                	Select Case char
                	
                	Case "n"
                		ret += chr(10)
                	
                	Case "c"
                		cleartext = false
                		
                	Case Else
	                        ret += char
	                        
	                End Select
	                
	        ElseIf cleartext = false Then
	        	If char = " " Then
	        		ret += chr( val( escapeChar ) )
	        		
	        		escapeChar = ""
	        		cleartext = true
	        	Else
	        		escapeChar += char
	        	Endif

                ElseIf cleartext Then
                        Select Case char
                        
                        Case "\"
                                ' Ignore escape char
                                
                        Case "%"
                                varName = ""
                                
                                Do
                                        i += 1
                                        char = chr(literal[i])
                                        
                                        If char <> "%" Then
                                                varName += char
                                        End If
                                Loop Until char = "%" or i = length
                                
                                ret += this.stack.getVar(varName)
                                
                        Case Else
                                ret += char
                                
                        End Select
                End If
        Next
        
        Return ret
End Function

'' Dump the pre-processed code for debug purposes, or maybe as a from of
'' lite obfuscation
Sub script.dumpCode( ByVal fileName As String )
	Dim As Integer file = FreeFile
	Dim As Integer lineCount = UBound(this.code, 1)
	
	Open fileName for output as #file
	
	For i As Integer = 0 to lineCount
		Dim As String outputLine
		
		For b As Integer = 0 to 6
			If inStr(this.code(i,b), " ") Then
				outputLine += chr(34) & this.code(i,b) & chr(34) & " "
			ElseIf this.code(i,b) = "" Then
				Exit For
			Else
				outputLine += this.code(i,b) & " "
			Endif
		Next
		
		Print #file, outputLine
	Next
	
	Close #file
End Sub

Sub script.dumpStack( ByVal fileName As String )
	this.stack.save(filename)
End Sub

Function script.varPtr( ByVal varName As String ) As String Ptr
	Return this.stack.varPtr( varName )
End Function

