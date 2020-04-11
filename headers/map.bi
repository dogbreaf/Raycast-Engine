' Manage map data
'

' Represents a 1x1 segment of the map
Type mapSegment
	solid		As Byte
	textureID	As LongInt
End Type

' Represents an object in the map
Type mapObject
	' The position of the object
	posX		As Double
	posY		As Double
	
	' The dimensions of the object
	width		As Double
	height		As Double
	
	' The ID of the texture to use
	textureID	As LongInt
End Type

' The map
type gameMap
	mapW		As LongInt
	mapH		As LongInt
	
	' The segments on the map
	segment ( Any, Any )	As mapSegment
	
	' The objects on the map
	mObject ( Any ) 	As mapObject
	
	Declare Constructor ( ByVal As Integer, ByVal As Integer )
	
	Declare Function addObject( ByVal As Double, ByVal As Double, ByVal As Double = 1, ByVal As Double = 1, ByVal As Integer ) As errorCode
	
	Declare Function load ( ByVal As String ) As errorCode
	Declare Function save ( ByVal As String ) As errorCode
end type

Constructor gameMap ( ByVal w As Integer, ByVal h As Integer )
	' Size the array
	ReDim this.segment( w, h ) As mapSegment
	
	this.mapW = w
	this.mapH = h
End Constructor

Function gameMap.addObject( ByVal x As Double, ByVal y As Double, ByVal w As Double = 1, ByVal h As Double = 1, ByVal tID As Integer ) As errorCode
	Dim As Integer count = UBound(this.mObject)+1
	
	ReDim Preserve this.mObject(count) As mapObject
	
	If UBound(this.mObject) <> count Then
		Return E_RESIZE_FAILED
	Endif
	
	this.mObject(count).posX = x
	this.mObject(count).posY = y
	
	this.mObject(count).width = w
	this.mObject(count).height = h
	
	this.mObject(count).textureID = tID

	Return E_NO_ERROR
End Function

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
        
        ' Load objects
        Dim As ULongInt objectCount
        
        Get #hndl,, objectCount
        
        ReDim this.mObject(objectCount) As mapObject
        
        If UBound(this.mObject) <> objectCount Then
                Return E_RESIZE_FAILED
        Endif
        
        For i As Integer = 0 to objectCount
                If err <> 0 Then
                        Return E_FILEIO_FAILED
                Endif
                If eof(hndl) Then
                        Return E_FILE_ENDED_UNEXPECTEDLY
                Endif
                
                Get #hndl,, this.mObject(i)
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
	
			Put #hndl,, this.segment( x, y )
		Next
	Next
        
        ' Save objects
        Dim As ULongInt objectCount = UBound(this.mObject)
        
        Put #hndl,, objectCount
        
        For i As Integer = 0 to objectCount
                If err <> 0 Then
                        Return E_FILEIO_FAILED
                Endif
                
                Put #hndl,, this.mObject(i)
        Next
	
	Close #hndl
	
	Return E_NO_ERROR
End Function

