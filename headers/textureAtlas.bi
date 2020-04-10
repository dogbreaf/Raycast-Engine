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
	
	Declare Sub saveAtlas( ByVal As String )
	Declare Sub loadAtlas( ByVal As String )
	
	Declare Sub save( ByVal As Integer )
	Declare Sub load( ByVal As Integer )
	
	Declare Sub loadTextures( ByVal As String, ByVal As Integer = -1, ByVal As Integer = -1 )
	Declare Sub setTexture( ByVal As Integer )
	
	Declare Sub addLargeTexture( ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Integer )
	Declare Sub addAnimatedTexture( ByVal As Integer, ByVal As Integer )
	
	Declare Constructor ()
	Declare Destructor ()
end type

Sub textureAtlas.saveAtlas( ByVal fname As String )
	If fname = "" Then
		Return
	Endif
	
	' Open a file and save the texture atlas data to it
	Dim As Integer	hndl = FreeFile
	
	Open fname For Output As #hndl
	
	this.save(hndl)
	
	Close #hndl
End Sub

Sub textureAtlas.loadAtlas( ByVal fname As String )
	' Safety checks
	If fname = "" Then
		Return
	Endif
	
	If not fileexists(fname) Then
		Return
	Endif
	
	' Open a file and load the texture atlas data from it
	Dim As Integer	hndl = FreeFile
	
	Open fname For Input As #hndl
	
	this.load(hndl)
	
	Close #hndl
End Sub

Sub textureAtlas.save( ByVal hndl As Integer )
	' Check for an open file
	If hndl = 0 Then
		Return
	Endif
	
	' Create and save a header
	Dim As textureAtlasHeader	header
	
	header.metaTextures = UBound(this.mTexture)
	header.textureSize = this.textureSize
	
	Put #hndl,, header
	
	' If there are meta-textures then save them
	For i As Integer = 0 to UBound(this.mTexture)
		Put #hndl,, this.mTexture(i)
	Next
	
	' Now save the texture
	Dim As Integer compression = CS_NONE
	
	' Use RLE for large images
	If ( this.atlas->width > 256 ) or ( this.atlas->height > 256 ) Then
		compression = CS_RLE
	Endif
	
	storeImageData(hndl, this.atlas, compression)
End Sub

Sub textureAtlas.load( ByVal hndl As Integer )
	' Make sure there is a file handle
	If hndl = 0 Then
		Return
	Endif
	
	' Create and read a header
	Dim As textureAtlasHeader	header
	
	Get #hndl,, header
	
	' Check the identifier
	If header.identifier <> &hAAEE Then
		Return
	Endif
	
	' Set variables
	this.textureSize = header.textureSize
	
	' Read any meta textures
	If header.metaTextures >= 0 Then
		ReDim this.mTexture(header.metaTextures) As metaTexture
		
		For i As Integer = 0 to header.metaTextures
			Get #hndl,, this.mTexture(i)
		Next
	Endif
	
	' Read the texture data
	readImageData(hndl, this.atlas)
	
	' set the texture to ID 0
	this.setTexture(0)
End Sub

Sub textureAtlas.loadTextures( ByVal fname As String, ByVal wIn As Integer = -1, ByVal hIn As Integer = -1 )
	' Sanity check
	If (fname = "") Then
		Return
	Endif
	
	' Get the texture size
	Dim As Long w = wIn
	Dim As Long h = hIn
	
	If (w = -1) or (h = -1) Then
		Dim As Integer hndl = FreeFile
		
		Open fname For Input As #hndl 
		
		Get #hndl, 19, w
		Get #hndl, 23, h
		
		Close #hndl
		
		If (w < 1) or (h < 1) Then
			Return
		Endif
	Endif
	
	' Avoid re-allocating the same buffers
	safeFree(this.texture)
	safeFree(this.atlas)
	
	' Alocate a buffer and load an image
	this.atlas = ImageCreate( w, h, rgb(255,255,255))
	this.texture = ImageCreate( this.textureSize, this.textureSize )
	
	BLoad fname, this.atlas
	
	' Load the first texture
	this.setTexture( 0 )
End Sub

Sub textureAtlas.setTexture( ByVal ID As Integer )
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
		Return
	Endif
	
	previousID = selectedID
	selectedID = ID
	
	' Make sure that the texture buffers have been initialised
	If (this.atlas = 0) Then
		Return
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
		
		End Select
	Endif
End Sub

Sub textureAtlas.addLargeTexture( ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer )
	Dim As Integer count = UBound(this.mTexture)+1
	
	ReDim Preserve this.mTexture( count ) As metaTexture
	
	this.mTexture(count).texType = T_LARGE
	
	this.mTexture(count).x = x
	this.mTexture(count).y = y
	this.mTexture(count).w = w
	this.mTexture(count).h = h
End Sub

Sub textureAtlas.addAnimatedTexture( ByVal startFrame As Integer, ByVal endFrame As Integer )
	Dim As Integer count = UBound(this.mTexture)+1
	
	ReDim Preserve this.mTexture( count ) As metaTexture
	
	this.mTexture(count).texType = T_ANIMATED
	
	this.mTexture(count).frameStart = startFrame
	this.mTexture(count).frameEnd = endFrame
End Sub

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

