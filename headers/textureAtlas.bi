' Load multiple textures from a single image
'

#include once "fbgfx.bi"

' Free an image without risk of double freeing it 
Sub safeFree( ByRef image As Any Ptr ) 
	If image <> 0 Then
		ImageDestroy(image):image = 0
	Endif
End Sub

' Texture atlas object
type textureAtlas
	atlas		As fb.image Ptr	' The entire texture atlas
	texture 	As fb.image Ptr	' The currently selected texture
	
	textureSize	As Integer = 32	' The texture size in pixels
	
	textureX	As Integer	' The pixel coords of the current texture
	textureY	As Integer
	
	Declare Sub loadTextures( ByVal As String, ByVal As Integer = 256, ByVal As Integer = 256 )
	Declare Sub setTexture( ByVal As Integer )
	
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
	' Make sure that the texture buffers have been initialised
	If (this.texture = 0) or (this.atlas = 0) Then
		Return
	Endif
	
	' Set up some variables
	Dim As Integer atlasW = this.atlas->width / this.textureSize
	Dim As Integer atlasH = this.atlas->height / this.textureSize
	
	Dim As Integer searchID
	
	' Find the X/Y Coordinate of the texture in the atlas
	For y As Integer = 0 to atlasH
		For x As Integer = 0 to atlasW
			If searchID = ID Then
				this.textureX = x*this.textureSize
				this.textureY = y*this.textureSize
				
				Exit For, For
			Endif
			
			searchID += 1
		Next
	Next
	
	' Set the texture buffer to contain the correct data
	Put this.texture, (0,0), this.atlas, (textureX, textureY)-Step(this.textureSize-1, this.textureSize-1), PSET
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

