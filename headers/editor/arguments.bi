' Track options passed on the commandline
'

' Get the value of a specific option (e.g. the file in "-f filename")
Function getArgument( ByVal opt As String ) As String
	Dim As Integer argNum
	
	Do
		argNum += 1
		
		If Command(argNum) = opt Then
			Return Command(argNum + 1)
		ElseIf Command(argNum) = "" Then
			Return ""
		Endif
	Loop
End Function

' Find out if an option was passed
Function getOption ( ByVal opt As String ) As Boolean
	Dim As Integer argNum
	
	Do
		argNum += 1
		
		If Command(argNum) = opt Then
			Return true
		ElseIf Command(argNum) = "" Then
			Return false
		Endif
	Loop
End Function

' Get the last argument
Function getLastArgument() As String
	Dim As Integer argNum
	
	Do
		argNum += 1
		
		If Command(argNum) = "" Then
			Return Command(argNum)
		Endif
	Loop
End Function

