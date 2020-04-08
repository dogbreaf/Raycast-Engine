' Load multiple textures from a single image
'

#include once "fbgfx.bi"

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
	frameStart	As Integer
	frameEnd	As Integer
	
	' Large texture info
	x		As Integer
	y		As Integer
	w		As Integer
	h		As Integer
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
	
	Declare Sub loadTextures( ByVal As String, ByVal As Integer = 256, ByVal As Integer = 256 )
	Declare Sub setTexture( ByVal As Integer )
	
	Declare Sub addLargeTexture( ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Integer )
	Declare Sub addAnimatedTexture( ByVal As Integer, ByVal As Integer )
	
	Declare Constructor ()
	Declare Destructor ()
end type

Sub textureAtlas.loadTextures( ByVal fname As String, ByVal w As Integer = 256, ByVal h As Integer = 256 )
	' Sanity check
	If (fname = "") or ( w < 1 ) or ( h < 1 ) Then
		Return
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
