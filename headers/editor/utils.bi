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

