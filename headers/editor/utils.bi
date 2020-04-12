' Draw an image scaled to a certain size
Sub scalePut( ByVal dest As Any Ptr = 0, ByVal xPos As Integer, ByVal yPos As Integer, _
	      ByVal w As Integer, ByVal h As Integer, ByVal image As Any Ptr )
	If image = 0 Then
		Return	
	Endif
	
	Dim As Double sampleX
	Dim As Double sampleY
	
	For y As Integer = 0 to h
		For x As Integer = 0 to w
			sampleX = (x/w)
			sampleY = (y/h)
			
			PSet dest, ( xPos + x, yPos + y), sampleTexture(sampleX, sampleY, image, SI_NEAREST)
		Next
	Next
End Sub

Sub debugPrint( ByVal s As String )
	Static As Integer hndl
	
	If hndl = 0 Then
		hndl = FreeFile
		
		Open Cons for Output As #hndl
	Endif
	
	Print #hndl, s
End Sub

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

' The back bar for getting user input and sending messages to the user
Sub blackBar(ByVal c As UInteger = 0)
	Do:Sleep 1,1:Loop Until InKey() = ""
	
	Line (0,0)-(__XRES, 8), c, BF
	Locate 1,1
End Sub

Function getConfirm( ByVal message As String ) As Boolean
	blackBar()
	Print message & " (Y/N)"
	
        Do:Sleep 1,1:Loop Until InKey() = ""
        
        Dim As String k
        
	Do
		Sleep 1,1
                
                k = InKey()
		
                If LCase(k) = "y" Then
                        Return true
                Endif
	Loop Until k <> ""
        
        blackBar()
        Print "Cancelled"
        Sleep 500
	
	Return false
End Function

Function errorDialouge(ByVal e As errorCode, ByVal trace As String) As Integer
	logError(e, trace, false)
	
	If e = 0 Then
		Return 0
	Endif
	
	blackBar(rgb(255,0,0))
	Draw String (0,0), "An error has occurred: " & errorStringify(e) & " at " & trace & ", press any key to continue..."
	
	Do:Sleep 1,1:Loop Until InKey() = ""
	Sleep

	Return 0
End Function

' Show a list of items with the selected item highlighted
Function selectList( _
                ByVal x As Integer, _
                ByVal y As Integer, _
                ByVal w As Integer, _
                ByVal h As Integer, _
                list(Any) As String, _
                ByVal selectID As Integer ) As errorCode
        
        Dim As Integer count = UBound(list)
        Dim As Integer listLength = (h/10)
        Dim As Integer listScroll = IIF( selectID > listLength, selectID - 2, 0 )
        
        Line (x-1,y-1)-Step(w+2,h+2),   rgb(255,255,255),       B
        Line (x,y)-Step(w,h),           rgb(40,40,40),          BF
        
        If selectID > count Then
                Return E_BAD_PARAMETERS
        Endif
        
        For i As Integer = 0 to listLength
                Dim As uInteger bg = rgb(0,0,0)
                Dim As uInteger fg = rgb(255,255,255)
                
                If i + listScroll > count Then
                        Exit For
                Endif
                
                If i + listScroll = selectID Then
                        bg = rgb(255,255,255)
                        fg = rgb(0,0,0)
                Endif
                
                Line (x, y + (i * 10 ))-step(w,10), bg, BF
                Draw String ( x + 2, y + ( i * 10 ) + 2 ), list(i + listScroll), fg
        Next
        
        Return E_NO_ERROR
End Function

