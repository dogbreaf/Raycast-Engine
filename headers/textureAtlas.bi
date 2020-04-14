' Load multiple textures from a single image
'

#include once "fbgfx.bi"
#include once "file.bi"
#include once "crt.bi"

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
        T_COMPOSITE
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
        
        Declare Function sampleTexture( ByVal As Double, ByVal As Double, ByVal As Integer, ByVal As Integer = 0 ) As UInteger
	
        Declare Function scalePut( ByVal As Any Ptr = 0, _
                                   ByVal As Integer, ByVal As Integer, _
                                   ByVal As Integer, ByVal As Integer, _
                                   ByVal As Integer ) As errorCode
        
	Declare Function addLargeTexture( ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Integer ) As errorCode
	Declare Function addAnimatedTexture( ByVal As Integer, ByVal As Integer ) As errorCode
        Declare Function addCompositeTexture( ByVal As Integer, ByVal As Integer ) As errorCode
	
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
                        
                Case T_COMPOSITE
                        ' Draw composite two textures
                        Dim As Integer bgID = workingTexture->frameStart
                        Dim As Integer fgID = workingTexture->frameEnd
                        
                        ' The temporary buffer used for the decal
                        Static As fb.Image Ptr tex
                        
                        ' Instead of seperately finding texture coords
                        ' I am using setTexture because it means you can
                        ' composite composite textures, large textures and
                        ' animated textures on top of eachoter as deep as you
                        ' want.
                        
                        ' Set the texture to the decal texture
                        this.setTexture(fgID)
                        
                        ' Copy that into a temp buffer
                        If tex = 0 Then
                                tex = ImageCreate( this.texture->width, this.texture->height )
                        ElseIf (tex->width <> this.texture->width) or (tex->height <> this.texture->height) Then
                                If tex <> 0 Then
                                        ImageDestroy(tex):tex = 0
                                Endif
                                
                                tex = ImageCreate( this.texture->width, this.texture->height )
                        Endif
                        
                        ' memcpy seems to be faster, but is causing segfaults
                        Put tex, (0,0), this.texture, PSET
                        'memcpy( tex, this.texture, sizeOf(fb.Image)+ tex->pitch * tex->height + tex->bpp * tex->width )
                        
                        ' Set the texture to the base texture
                        this.setTexture(bgID)
                        
                        ' Composite the decal texture on top
                        Put this.texture, (0,0), tex, TRANS
			
		Case Else
			Return E_UNKNOWN
		
		End Select
	Else
		Return E_BAD_PARAMETERS
	Endif
	
	Return E_NO_ERROR
End Function

' Sample directly from the atlas
Function textureAtlas.sampleTexture( ByVal sX As Double, ByVal sY As Double, ByVal tID As Integer, ByVal i As Integer = 0 ) As UInteger
        ' The position of the target texture
        Dim As Integer tX
        Dim As Integer tY
        Dim As Integer tW
        Dim As Integer tH
        
        ' The size of the atlas in textures
        Dim As Integer atlasW = this.atlas->width / this.textureSize
	Dim As Integer atlasH = this.atlas->height / this.textureSize
        
        ' The output
        Dim As UInteger sample
        
        ' Update the animation timer	
	If 1000*(timer-FrameTimer) > 250 Then
		frameNumber += 1
		
		If frameNumber > 1024 Then
			frameNumber = 0
		Endif
		
		frameTimer = timer
	Endif
        
        ' Make sure there is a texture to sample
        If this.atlas = 0 Then
                logError(E_NO_BUFFER, __errorTrace, false)
                Return 0
        Endif
        
        ' Calculate the texture position in the texture atlas
        If tID < 2048 Then
                If (tID < 0) or (tID > (atlasW * atlasH)) Then
                        logError(E_BAD_PARAMETERS, __errorTrace, false)
                        
                        Return 0
                Endif
        Else
                If (tID-2048) > Ubound(this.mTexture) Then
                        logError(E_BAD_PARAMETERS, __errorTrace, false)
                        
                        Return 0
                Endif
        Endif
        
        ' Find the texture coords
        If tID < 2048 Then
                ' Get the position of a regular texture
                Dim As Integer searchID
                
                ' Find the X/Y Coordinate of the texture in the atlas
		For y As Integer = 0 to atlasH-1
			For x As Integer = 0 to atlasW-1
				If searchID = tID Then
					tX = x*this.textureSize
					tY = y*this.textureSize
					
					Exit For, For
				Endif
				
				searchID += 1
			Next
		Next
                
                ' The width and height are standard
                tW = this.textureSize
                tH = this.textureSize
                
        Else
                Dim As metaTexture Ptr  workingTexture = @this.mTexture(tID-2048)
                
                Select Case workingTexture->texType
                
                Case T_LARGE
                        ' The coords are in the texture
                        tX = workingTexture->X
                        tY = workingTexture->Y
                        tW = workingTexture->w
                        tH = workingTexture->h
                        
                Case T_ANIMATED
                        ' The coords move depending on the frame
                        Dim As Integer searchID
                        Dim As Integer frameID = frameNumber mod (workingTexture->frameEnd - workingTexture->frameStart)
			
			frameID += workingTexture->frameStart
                        
                        ' Get the sample from the correct frame
                        Return this.sampleTexture( sX, sY, frameID, i )
                
                Case T_COMPOSITE
                        ' This could be from either texture
                        sample = this.sampleTexture( sX, sY, workingTexture->frameEnd, i)
                        
                        If (sample and rgb(255,255,255)) = rgb(255,0,255) Then
                                Return this.sampleTexture( sX, sY, workingTexture->frameStart, i)
                        Else
                                Return sample
                        Endif
                Case Else
                        
                        Return 0
                        
                End Select
        Endif
        
        ' Sample the correct location
        Dim As Integer sampleX = tX + ( frac(sX) * (tW - 1) )
        Dim As Integer sampleY = tY + ( frac(sY) * (tH - 1) )
        
        ' Make sure we don't create an out of bounds pointer
        If ( 0 < sampleX < this.atlas->width ) and ( 0 < sampleY < this.atlas->height ) Then
                'consolePrint( this.atlas->width & " " & this.atlas->height )
                'consolePrint( sampleX & " " & sampleY )
                'logError(E_BAD_DATA, __errorTrace, true)
                
                'Return 0
        Endif
        
        ' Get a pointer to the correct pixel
        Dim As UInteger Ptr ret = ( cast(Any Ptr, this.atlas) + sizeOf(fb.Image) + this.atlas->pitch * sampleY + this.atlas->bpp * sampleX )
        
        Return *ret
End Function

' Draw a texture in an unusual shape
Function textureAtlas.scalePut( ByVal dest As Any Ptr = 0, _
                   ByVal x As Integer, ByVal y As Integer, _
                   ByVal w As Integer, ByVal h As Integer, _
                   ByVal tID As Integer ) As errorCode
                   
        For a As Integer = 0 to h
                For b As Integer = 0 to w
                        Dim As UInteger sample
                        
                        sample = this.sampleTexture( (b/w), (a/h), tID )
                        
                        If ( sample and rgb(255,255,255) ) <> rgb(255,0,255) Then
                                PSet dest, ( x + b, y + a ), sample
                        Endif
                Next
        Next
        
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

Function textureAtlas.addCompositeTexture( ByVal startFrame As Integer, ByVal endFrame As Integer ) As errorCode
	Dim As Integer count = UBound(this.mTexture)+1
	
	ReDim Preserve this.mTexture( count ) As metaTexture
	
	If UBound(this.mTexture) < count Then
		Return E_RESIZE_FAILED
	Endif
	
	this.mTexture(count).texType = T_COMPOSITE
	
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

