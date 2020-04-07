' Manage map data
'

' Represents a 1x1 segment of the map
Type mapSegment
	solid		As Byte
	textureID	As Integer
End Type

' The map
type gameMap
	mapW		As Integer
	mapH		As Integer
	
	segment ( Any, Any )	As mapSegment
	
	Declare Constructor ( ByVal As Integer, ByVal As Integer )
	
	Declare Sub load ( ByVal As String ) 
	Declare Sub save ( ByVal As String )
end type

Constructor gameMap ( ByVal w As Integer, ByVal h As Integer )
	' Size the array
	ReDim this.segment( w, h ) As mapSegment
	
	this.mapW = w
	this.mapH = h
End Constructor

Sub gameMap.load( ByVal fname As String )
	' Load the data from a file
	Dim As Integer hndl = FreeFile
	
	Open fname For Binary As #hndl
	
	Get #hndl,, mapW
	Get #hndl,, mapH
	
	ReDim this.segment( mapW, mapH ) As mapSegment
	
	For y As Integer = 0 to mapH
		For x As Integer = 0 to mapW
			Get #hndl,, this.segment( x, y )
		Next
	Next
	
	Close #hndl
End Sub

Sub gameMap.save( ByVal fname As String )
	' Save the data to a file
	Dim As Integer hndl = FreeFile
	
	Open fname For Binary As #hndl
	
	Put #hndl,, mapW
	Put #hndl,, mapH
	
	For y As Integer = 0 to mapH
		For x As Integer = 0 to mapW
			Put #hndl,, this.segment( x, y )
		Next
	Next
	
	Close #hndl
End Sub

