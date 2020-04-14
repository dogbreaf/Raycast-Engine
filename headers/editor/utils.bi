' Let the user know something is happening
Sub LoadingIndicator( ByVal line1 As String = "Loading...", ByVal line2 As String = "" )
	Line ( (__XRES/2)-(Len(line1)*4)-4, (__YRES/2)-(12) )-STEP( (Len(line1)*8)+8, 24 ), rgb( 0, 0, 0 ), BF
	Line ( (__XRES/2)-(Len(line1)*4)-4, (__YRES/2)-(12) )-STEP( (Len(line1)*8)+8, 24 ), rgb( 255, 255, 255 ), B
	
	Draw String ( (__XRES/2)-(len(line1)*4), (__YRES/2)-10 ), line1, rgb(255,255,255)
	Draw String ( (__XRES/2)-(len(line2)*4), (__YRES/2) ), line2, rgb(255,255,255)
End Sub

' Hotkeys
Function userHotkey( ByVal key As Integer, ByVal modifier As Integer = -1, ByVal block As Boolean = true ) As Boolean
	Dim As Boolean	ret
	
	' Check if the key is pressed
	If Multikey(key) and IIF( modifier = -1, -1, Multikey(modifier)) Then
		ret = true
		
		' Prevent keys being repeated too quickly
		Sleep 10,1
	Endif
	
	' Wait for keyUp to prevent key repeats 
	If block and ret Then
		Do:Sleep 10,1:Loop Until not Multikey(key)
	Endif
	
	' Return true/false
	Return ret
End Function
