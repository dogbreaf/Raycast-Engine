' Commonly needed error codes
'

#define __errorTrace __FILE__ & "(" & __LINE__ & ") in function " & __FUNCTION__

Enum errorCode
	E_NO_ERROR
	E_UNKNOWN
	
	E_NO_FILE_SPECIFIED
	E_FILEIO_FAILED
	E_FILE_NOT_FOUND
	E_WRONG_FILETYPE
	E_FILE_ENDED_UNEXPECTEDLY
	
	E_NO_BUFFER
	E_BAD_PARAMETERS
	E_RESIZE_FAILED
	
	E_BAD_POINTER
	E_BAD_DATA
	
	E_MAXVAL
End Enum

' Convert from a code to a string
Function errorStringify( ByVal e As errorCode ) As String
	Dim As String errorStrings(E_MAXVAL) = { _
						"", _
						"Unknown error", _
						_
						"No file specified", _
						"File I/O failed", _
						"File not found", _
						"Unexpected filetype", _
						"File ended unexpectedly", _
						_
						"Image buffer did not exist/was not created", _
						"Parameters were out of bounds", _
						"Failed to resize dynamic array", _
						_
						"Pointer was NULL, expected address", _
						"Data is out of bounds/Illegal data" _
					}
					
	If e < E_MAXVAL Then
		Return errorStrings(e)
	Else
		Return "Error code out of bounds"
	Endif
End Function

' Log an error to stdErr/the console
Function logError( ByVal errorNumber As errorCode, ByVal trace As String = "Unknown(0) in Unknown()", ByVal fatal As Boolean = false ) As errorCode
	If errorNumber = E_NO_ERROR Then
		Return E_NO_ERROR
	Endif
	
	Dim As Integer hndl = FreeFile
	
	If hndl = 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	Open Err For Output As #hndl
	
	If err <> 0 Then
		Return E_FILEIO_FAILED
	Endif
	
 	Print #hndl, "Error, " & trace & ": " & errorStringify(errorNumber)
	
	Close #hndl
	
	If fatal Then
		End errorNumber
	Endif
	
	Return E_NO_ERROR
End Function

Function consolePrint( ByVal text As String ) As errorCode
	Dim As Integer hndl = FreeFile
	
	If hndl = 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	Open Err For Output As #hndl
	
	If err <> 0 Then
		Return E_FILEIO_FAILED
	Endif
	
 	Print #hndl, text
	
	Close #hndl

	Return E_NO_ERROR
End Function

