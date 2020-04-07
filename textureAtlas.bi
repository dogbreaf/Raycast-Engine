' Load multiple textures from a single image
'

#include once "fbgfx.bi"

type textureAtlas
	atlas		As fb.image Ptr	' The entire texture atlas
	texture 	As fb.image Ptr	' The currently selected texture
	
	textureSize	As Integer = 32	' The texture size in pixels
	
	Declare Sub loadTextures( ByVal As String, ByVal As Integer = 256, ByVal As Integer = 256 )
	Declare Sub setTexture( ByVal As Integer )
	
	Declare Destructor ()
end type

Sub textureAtlas.loadTextures( ByVal fname As String, ByVal w As Integer = 256, ByVal h As Integer = 256 )
	' Sanity check
	If (fname = "") or ( w < 1 ) or ( h < 1 ) Then
		Return
	Endif
	
	' Avoid re-allocating the same buffers
	If this.atlas <> 0 Then
		ImageDestroy( this.atlas )
		this.atlas = 0
	Endif
	
	If this.texture <> 0 Then
		ImageDestroy( this.texture )
		this.atlas = 0
	Endif
	
	' Alocate a buffer and load an image
	this.atlas = ImageCreate( w, h, rgb(255,255,255))
	this.texture = ImageCreate( this.textureSize, this.textureSize )
	
	BLoad fname, this.atlas
	
	' Load the first texture
	this.setTexture( 0 )
End Sub

Sub textureAtlas.setTexture( ByVal ID As Integer )
	' Set up some variables
	Dim As Integer atlasW = this.atlas->width / this.textureSize
	Dim As Integer atlasH = this.atlas->height / this.textureSize
	
	Dim As Integer textureX
	Dim As Integer textureY
	
	Dim As Integer searchID
	
	' Find the X/Y Coordinate of the texture in the atlas
	For y As Integer = 0 to atlasH
		For x As Integer = 0 to atlasW
			If searchID = ID Then
				textureX = x*this.textureSize
				textureY = y*this.textureSize
				
				Exit For, For
			Endif
			
			searchID += 1
		Next
	Next
	
	' Set the texture buffer to contain the correct data
	Put this.texture, (0,0), this.atlas, (textureX, textureY)-Step(this.textureSize-1, this.textureSize-1), PSET
End Sub

Destructor textureAtlas()
	' Clean up
	If this.atlas <> 0 Then
		ImageDestroy( this.atlas )
	Endif
	
	If this.texture <> 0 Then
		ImageDestroy( this.texture )
	Endif
End Destructor

