' Manage map data
'

' Represents a 1x1 segment of the map
Type mapSegment
	solid		As Byte
	textureID	As LongInt
End Type

' The map
type gameMap
	mapW		As LongInt
	mapH		As LongInt
	
	segment ( Any, Any )	As mapSegment
	
	Declare Constructor ( ByVal As Integer, ByVal As Integer )
	
	Declare Function load ( ByVal As String ) As errorCode
	Declare Function save ( ByVal As String ) As errorCode
end type

Constructor gameMap ( ByVal w As Integer, ByVal h As Integer )
	' Size the array
	ReDim this.segment( w, h ) As mapSegment
	
	this.mapW = w
	this.mapH = h
End Constructor

Function gameMap.load( ByVal fname As String ) As errorCode
	' Load the data from a file
	Dim As Integer hndl = FreeFile
	
	If hndl = 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	Open fname For Binary As #hndl
	
	If err <> 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	Get #hndl,, mapW
	Get #hndl,, mapH
	
	ReDim this.segment( mapW, mapH ) As mapSegment
	
	For y As Integer = 0 to mapH
		For x As Integer = 0 to mapW
			If err <> 0 Then
				Return E_FILEIO_FAILED
			Endif
			If eof(hndl) Then
				Return E_FILE_ENDED_UNEXPECTEDLY
			Endif
	
			Get #hndl,, this.segment( x, y )
		Next
	Next
	
	Close #hndl
	
	Return E_NO_ERROR
End Function

Function gameMap.save( ByVal fname As String ) As errorCode
	' Save the data to a file
	Dim As Integer hndl = FreeFile
	
	If hndl = 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	Open fname For Binary As #hndl
	
	If err <> 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	Put #hndl,, mapW
	Put #hndl,, mapH
	
	For y As Integer = 0 to mapH
		For x As Integer = 0 to mapW
			If err <> 0 Then
				Return E_FILEIO_FAILED
			Endif
			
			If eof(hndl) Then
				Return E_FILE_ENDED_UNEXPECTEDLY
			Endif
	
			Put #hndl,, this.segment( x, y )
		Next
	Next
	
	Close #hndl
	
	Return E_NO_ERROR
End Function

