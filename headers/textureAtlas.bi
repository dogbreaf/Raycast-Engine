' Load multiple textures from a single image
'

#include once "fbgfx.bi"
#include once "file.bi"

' Free an image without risk of double freeing it 
Sub safeFree( ByRef image As Any Ptr ) 
	If image <> 0 Then
		ImageDestroy(image):image = 0
	Endif
End Sub

' Meta-textures (i.e. larger textures and animated textures)
enum textureType
	T_LARGE		= 1
	T_ANIMATED
end enum

type metaTexture
	texType		As textureType
	
	' Animated texture info
	frameStart	As LongInt
	frameEnd	As LongInt
	
	' Large texture info
	x		As LongInt
	y		As LongInt
	w		As LongInt
	h		As LongInt
end type

' Texture atlas file header
type textureAtlasHeader
	identifier As LongInt = &hAAEE
	
	textureSize	As ULong
	metaTextures	As ULong
end type

' Texture atlas object
type textureAtlas
	atlas		As fb.image Ptr	' The entire texture atlas
	texture 	As fb.image Ptr	' The currently selected texture
	
	textureSize	As Integer = 32	' The texture size in pixels
	
	textureX	As Integer	' The pixel coords of the current texture
	textureY	As Integer
	
	mTexture(Any)	As metaTexture	' ID's above 2048 represent one of these textures
	
	frameTimer	As Double	' Timer to track animated textures
	frameNumber	As Integer	' Which frame of animated textures to display
	
	selectedID	As Integer	' the current ID
	previousID	As Integer	' the previous ID
	
	Declare Function saveAtlas( ByVal As String ) As errorCode
	Declare Function loadAtlas( ByVal As String ) As errorCode
	
	Declare Function save( ByVal As Integer ) As errorCode
	Declare Function load( ByVal As Integer ) As errorCode
	
	Declare Function loadTextures( ByVal As String, ByVal As Integer = -1, ByVal As Integer = -1 ) As errorCode
	Declare Function setTexture( ByVal As Integer ) As errorCode
	
	Declare Function addLargeTexture( ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Integer ) As errorCode
	Declare Function addAnimatedTexture( ByVal As Integer, ByVal As Integer ) As errorCode
	
	Declare Constructor ()
	Declare Destructor ()
end type

Function textureAtlas.saveAtlas( ByVal fname As String ) As errorCode
	If fname = "" Then
		Return E_NO_FILE_SPECIFIED
	Endif
	
	Dim As errorCode ec = E_NO_ERROR
	
	' Open a file and save the texture atlas data to it
	Dim As Integer	hndl = FreeFile
	
	If hndl = 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	Open fname For Binary As #hndl
	
	If err <> 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	ec = this.save(hndl)
	
	Close #hndl
	
	Return ec
End Function

Function textureAtlas.loadAtlas( ByVal fname As String ) As errorCode
	' Safety checks
	If fname = "" Then
		Return E_NO_FILE_SPECIFIED
	Endif
	
	If not fileexists(fname) Then
		Return E_FILE_NOT_FOUND
	Endif
	
	Dim As errorCode ec = E_NO_ERROR
	
	' Open a file and load the texture atlas data from it
	Dim As Integer	hndl = FreeFile
	
	If hndl = 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	Open fname For Binary As #hndl
	
	If err <> 0 Then
		Return E_FILEIO_FAILED
	Endif
	
	ec = this.load(hndl)
	
	Close #hndl
	
	Return ec
End Function

Function textureAtlas.save( ByVal hndl As Integer ) As errorCode
	' Check for an open file
	If hndl = 0 Then
		Return E_NO_FILE_SPECIFIED
	Endif
	
	' Create and save a header
	Dim As textureAtlasHeader	header
	
	header.metaTextures = UBound(this.mTexture)
	header.textureSize = this.textureSize
	
	Put #hndl,, header
	
	' If there are meta-textures then save them
	For i As Integer = 0 to UBound(this.mTexture)
		If err <> 0 Then
			Return E_FILEIO_FAILED
		Endif
		
		Put #hndl,, this.mTexture(i)
	Next
	
	' Now save the texture
	Dim As Integer compression = CS_NONE
	
	' Use RLE for large images
	If ( this.atlas->width > 256 ) or ( this.atlas->height > 256 ) Then
		compression = CS_RLE
	Endif
	
	Return storeImageData(hndl, this.atlas, compression)
End Function

Function textureAtlas.load( ByVal hndl As Integer ) As errorCode
	' Make sure there is a file handle
	If hndl = 0 Then
		Return E_NO_FILE_SPECIFIED
	Endif
	
	' Create and read a header
	Dim As textureAtlasHeader	header
	
	Get #hndl,, header
	
	' Check the identifier
	If header.identifier <> &hAAEE Then
		Return E_WRONG_FILETYPE
	Endif
	
	' Set variables
	this.textureSize = header.textureSize
	
	' Read any meta textures
	If header.metaTextures >= 0 Then
		ReDim this.mTexture(header.metaTextures) As metaTexture
		
		For i As Integer = 0 to header.metaTextures
			If err <> 0 Then
				Return E_FILEIO_FAILED
			Endif
			
			Get #hndl,, this.mTexture(i)
		Next
	Endif
	
	' Read the texture data
	Dim As errorCode ec = readImageData(hndl, this.atlas)
	
	If ec <> E_NO_ERROR Then
		Return ec 
	Endif
	
	' set the texture to ID 0
	Return this.setTexture(0)
End Function

Function textureAtlas.loadTextures( ByVal fname As String, ByVal wIn As Integer = -1, ByVal hIn As Integer = -1 ) As errorCode
	' Sanity check
	If (fname = "") Then
		Return E_NO_FILE_SPECIFIED
	Endif
	
	' Get the texture size
	Dim As Long w = wIn
	Dim As Long h = hIn
	
	If (w = -1) or (h = -1) Then
		Dim As Integer hndl = FreeFile
		
		Open fname For Binary As #hndl 
		
		Get #hndl, 19, w
		Get #hndl, 23, h
		
		Close #hndl
		
		If (w < 1) or (h < 1) Then
			Return E_WRONG_FILETYPE
		Endif
	Endif
	
	' Avoid re-allocating the same buffers
	safeFree(this.texture)
	safeFree(this.atlas)
	
	' Alocate a buffer and load an image
	this.atlas = ImageCreate( w, h, rgb(255,255,255))
	this.texture = ImageCreate( this.textureSize, this.textureSize )
	
	If (this.atlas = 0) or (this.texture = 0) Then
		Return E_NO_BUFFER
	Endif
	
	BLoad fname, this.atlas
	
	' Load the first texture
	Return this.setTexture( 0 )
End Function

Function textureAtlas.setTexture( ByVal ID As Integer ) As errorCode
	' Update the animation timer	
	If 1000*(timer-FrameTimer) > 250 Then
		frameNumber += 1
		
		If frameNumber > 1024 Then
			frameNumber = 0
		Endif
		
		frameTimer = timer
	Endif
	
	' Only update if the id is different
	If ID = previousID Then
		Return E_NO_ERROR
	Endif
	
	previousID = selectedID
	selectedID = ID
	
	' Make sure that the texture buffers have been initialised
	If (this.atlas = 0) Then
		Return E_NO_BUFFER
	ElseIf (this.texture = 0) Then
		this.texture = ImageCreate(this.textureSize, this.textureSize)
	Endif
	
	' Set up some variables
	Dim As Integer atlasW = this.atlas->width / this.textureSize
	Dim As Integer atlasH = this.atlas->height / this.textureSize
	
	Dim As Integer searchID
	
	If ID < 2048 Then
		' Find the X/Y Coordinate of the texture in the atlas
		For y As Integer = 0 to atlasH-1
			For x As Integer = 0 to atlasW-1
				If searchID = ID Then
					this.textureX = x*this.textureSize
					this.textureY = y*this.textureSize
					
					Exit For, For
				Endif
				
				searchID += 1
			Next
		Next
		
		' Check the output buffer is the correct size
		If ( this.texture->width <> this.textureSize ) or ( this.texture->height <> this.textureSize ) Then
			safeFree(this.texture)
			
			this.texture = ImageCreate( this.textureSize, this.textureSize )
		Endif
		
		' Set the texture buffer to contain the correct data
		Put this.texture, (0,0), this.atlas, (textureX, textureY)-Step(this.textureSize-1, this.textureSize-1), PSET
		
	ElseIf ( ID-2048 ) <= UBound(this.mTexture) Then
		Dim As metaTexture Ptr	workingTexture = @this.mTexture(ID-2048)
		
		Select Case workingTexture->texType
		
		Case T_LARGE
			' Draw the large texture
			textureX = workingTexture->x
			textureY = workingTexture->y
			
			safeFree(this.texture)
			this.texture = ImageCreate( workingTexture->w, workingTexture->h )
			
			Put this.texture, (0,0), this.atlas, (textureX, textureY)-Step( workingTexture->w, workingTexture->h ), PSET
		
		Case T_ANIMATED
			' Draw whatever is the correct frame of the animate
			Dim As Integer frameID = frameNumber mod (workingTexture->frameEnd - workingTexture->frameStart)
			
			frameID += workingTexture->frameStart
			
			this.setTexture(frameID)
			
		Case Else
			Return E_UNKNOWN
		
		End Select
	Else
		Return E_BAD_PARAMETERS
	Endif
	
	Return E_NO_ERROR
End Function

Function textureAtlas.addLargeTexture( ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer ) As errorCode
	Dim As Integer count = UBound(this.mTexture)+1
	
	ReDim Preserve this.mTexture( count ) As metaTexture
	
	If UBound(this.mTexture) < count Then
		Return E_RESIZE_FAILED
	Endif
	
	this.mTexture(count).texType = T_LARGE
	
	If (x > this.atlas->width) or (y > this.atlas->height) or _
		(x+w > this.atlas->width) or (y+h > this.atlas->height) or _
		( w < 1 ) or ( h < 1 ) Then
		
		Return E_BAD_PARAMETERS
	Endif
	
	this.mTexture(count).x = x
	this.mTexture(count).y = y
	this.mTexture(count).w = w
	this.mTexture(count).h = h
	
	Return E_NO_ERROR
End Function

Function textureAtlas.addAnimatedTexture( ByVal startFrame As Integer, ByVal endFrame As Integer ) As errorCode
	Dim As Integer count = UBound(this.mTexture)+1
	
	ReDim Preserve this.mTexture( count ) As metaTexture
	
	If UBound(this.mTexture) < count Then
		Return E_RESIZE_FAILED
	Endif
	
	this.mTexture(count).texType = T_ANIMATED
	
	If (startFrame > endFrame) or (endFrame = 0) Then
		Return E_BAD_PARAMETERS
	Endif
	
	this.mTexture(count).frameStart = startFrame
	this.mTexture(count).frameEnd = endFrame
	
	Return E_NO_ERROR
End Function

Constructor textureAtlas()
	' Initialise with default texture
	safeFree(this.texture)
	safeFree(this.atlas)
	
	this.atlas = ImageCreate( this.textureSize*8, this.textureSize*8, rgb(255,0,255) )
	this.texture = ImageCreate( this.textureSize, this.textureSize)
	
	' Generate a missing texture texture
	For y As Integer = 0 to this.textureSize*8 STEP 16
		For x As Integer = 0 to this.textureSize*8 STEP 16
			Line this.atlas, (x,y)-STEP(8,8), rgb(0,0,0), BF
			Line this.atlas, (x+8, y+8)-STEP(8,8), rgb(0,0,0), BF
		Next
	Next
	
	' Init the texture
	this.setTexture(0)
	
	'
	frameTimer = timer
End Constructor

Destructor textureAtlas()
	' Clean up
	If this.atlas <> 0 Then
		ImageDestroy( this.atlas )
	Endif
	
	If this.texture <> 0 Then
		ImageDestroy( this.texture )
	Endif
End Destructor

