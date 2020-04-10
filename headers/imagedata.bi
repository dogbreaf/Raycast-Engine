' Read and write image data from an already open file
'

#include once "fbgfx.bi"

' Possible compression schemes
enum compressionScheme
	CS_NONE
	CS_RLE
end enum

' Image header
type imageHeader
	identifier As LongInt = &hAAFF
	
	width As LongInt
	height As LongInt
	
	bitDepth As Byte = sizeOf(UByte)*4
	
	compression As Byte = CS_NONE
end type

Function storeImageData( ByVal hndl As Integer, ByVal image As fb.image Ptr, ByVal storeMethod As compressionScheme = CS_NONE ) As errorCode
	' There is no image data to save or no open file to write to
	If (image = 0) or (hndl = 0) Then
		Return E_BAD_PARAMETERS
	Endif
	
	' This would just cause problems at the moment tbh
	If (image->bpp)*8 <> 32 Then
		Return E_BAD_PARAMETERS
	Endif
	
	' create a header
	Dim As imageHeader header
	
	header.width = image->width
	header.height = image->height
	
	header.bitDepth = (image->bpp)*8
	
	header.compression = storeMethod
	
	' Save the header to the file
	Put #hndl,, header
	
	If err <> 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	' Save the data
	Select Case storeMethod
	
	Case CS_NONE
		' Create some variables
		Dim As ULong Ptr pixelData
		
		' Store uncompressed data
		For y As Integer = 0 to header.height
			For x As Integer = 0 to header.width
				pixelData = ( cast(Any Ptr, image) + sizeOf(fb.image) + image->pitch * y + image->bpp * x )
				
				If pixelData = 0 Then
					Return E_BAD_POINTER
				Endif
				
				Put #hndl,, *pixelData
				
				If err <> 0 Then
					Return E_FILEIO_FAILED
				Endif
			Next
		Next
	
	Case CS_RLE
		' Create some variables
		Dim As ULong Ptr	pixelData
		Dim As ULong		prevPixelData
		Dim As ULong		pixelCount
		
		' Use run-length encoding
		For y As Integer = 0 to header.height
			For x As Integer = 0 to header.width
				pixelData = ( cast(Any Ptr, image) + sizeOf(fb.image) + image->pitch * y + image->bpp * x )
				
				If pixelData = 0 Then
					Return E_BAD_POINTER
				Endif
				
				If prevPixelData <> *pixelData Then
					Put #hndl,, prevPixelData
					Put #hndl,, pixelCount
					
					' Its one and not 0 because we count the current pixel
					pixelCount = 1
				Else
					pixelCount += 1
				Endif
				
				prevPixelData = *pixelData
				
				If err <> 0 Then
					Return E_FILEIO_FAILED
				Endif
			Next
		Next
		
		' Write the last pixels
		Put #hndl,, *pixelData
		Put #hndl,, pixelCount
		
		If err <> 0 Then
			Return E_FILEIO_FAILED
		Endif
	Case Else
		Return E_BAD_PARAMETERS
	End Select
	
	Return E_NO_ERROR
End Function

Function readImageData( ByVal hndl As Integer, ByRef image As Any Ptr ) As errorCode
	' Make sure there is a file to read from
	If hndl = 0 Then
		Return E_BAD_PARAMETERS
	Endif
	
	' Create an empty header
	Dim As imageHeader header
	
	' Read the header info
	Get #hndl,, header
	
	' Check the header identifier is correct
	If header.identifier <> &hAAFF Then
		Return E_WRONG_FILETYPE
	Endif
	
	' Make sure the image has a size etc.
	If (header.width < 1) or (header.height < 1) or (header.bitDepth <> 32) Then
		Return E_BAD_DATA
	Endif
	
	' Ensure the image we are loading into does not exist yet
	If image <> 0 Then
		ImageDestroy(image):image = 0
	Endif
	
	' Create an image buffer for the image data
	image = ImageCreate(header.width, header.height)
	
	If image = 0 Then
		Return E_NO_BUFFER
	Endif
	
	' Read the image data
	Select Case header.compression
	
	Case CS_NONE
		' Create some variables
		Dim As ULong pixelData
		
		' Read raw image data
		For y As Integer = 0 to header.height-1
			For x As Integer = 0 to header.width
				Get #hndl,, pixelData
				
				If err <> 0 Then
					Return E_FILEIO_FAILED
				Endif
				
				If eof(hndl) Then
					Return E_FILE_ENDED_UNEXPECTEDLY
				Endif
				
				PSet image, (x,y), pixelData
			Next
		Next
		
	Case CS_RLE
		' Decompress RLE image data
		Dim As ULong pixelCount
		Dim As ULong pixelData
		
		Dim As Integer x
		Dim As Integer y
		
		Do
			Get #hndl,, pixelData
			Get #hndl,, pixelCount
			
			If err <> 0 Then
				Return E_FILEIO_FAILED
			Endif
			
			For i As Integer = 1 to pixelCount
				PSet image, (x,y), pixelData
				
				x += 1
				
				If x > header.width Then
					x = 0
					y += 1
				Endif
			Next
			
			If eof(hndl) Then
				Return E_FILE_ENDED_UNEXPECTEDLY
			Endif
		Loop Until ( x >= header.width ) and ( y >= header.height )
		
	Case Else
		Return E_BAD_DATA
		
	End Select
	
	Return E_NO_ERROR
End Function

