' Do the heavy lifting
'

#include once "fbgfx.bi"

#define _pi 3.141596

' Pixel format
union tPixel
	value As uInteger
	type
		b As uByte
		g As uByte
		r As uByte
		a As uByte
	end type
end union

' Sample a texture
Enum sampleInterpolation
	SI_NEAREST
	SI_WEIGHTED
	SI_COSINE
End Enum

' Much faster than point()
Function fastPoint( ByVal x As Integer, ByVal y As Integer, ByVal b As fb.Image Ptr ) As UInteger
	Dim As UInteger Ptr ret = new UInteger
	
	If ( x < b->width ) and ( y < b->height ) Then
		ret = ( cast(Any Ptr, b) + sizeOf(fb.Image) + b->pitch * y + b->bpp * x )
	Endif
	
	Return *ret
End Function

' Interpolate between two colors using weighted averages
Function weightColors( ByVal c1 As UInteger, ByVal c2 As UInteger, ByVal weight As Double ) As UInteger
	Dim As tPixel ret
	
	Dim As tPixel v1
	Dim As tPixel v2
	
	v1.value = c1
	v2.value = c2
	
	ret.r = (v1.r*(1-frac(weight))) + (v2.r*frac(weight))
	ret.g = (v1.g*(1-frac(weight))) + (v2.g*frac(weight))
	ret.b = (v1.b*(1-frac(weight))) + (v2.b*frac(weight))
	ret.a = (v1.a*(1-frac(weight))) + (v2.a*frac(weight))
	
	Return ret.value
End Function

Function sampleTexture( ByVal sx As Double, _
			ByVal sy As Double, _
			ByVal b As fb.Image Ptr, _
			ByVal method As sampleInterpolation = SI_NEAREST ) As UInteger
			
        Dim As UInteger ret
        
        If b = 0 Then
        	Return 0
        Endif
        
        Select Case method
        
        Case SI_NEAREST
        	' Just choose the nearest pixel
		Dim As Integer x = (b->width-1)*frac(sx)
		Dim As Integer y = (b->height-1)*frac(sy)
		
		If x > b->width Then
		        x = b->width
		Endif
		If y > b->height Then
		        y = b->height
		Endif
		
		ret = fastPoint(x,y,b)
		
	Case SI_WEIGHTED
		' Linearly interpolate using weighted averages
		Dim As Double x = (b->width-1)*frac(sx)
		Dim As Double y = (b->height-1)*frac(sy)
		
		Dim As Double weightX = frac(x)
		Dim As Double weightY = frac(y)
		
		x = CInt(x)
		y = CInt(y)
		
		' Don't sample past the end of the texture
		If x >= b->width Then
			x = b->width-1
		Endif
		If y >= b->height Then
			y = b->height-1
		Endif
		
		Dim As uInteger s1 = fastPoint(x,  y,  b)
		Dim As uInteger s2 = fastPoint(x,  y+1,b)
		Dim As uInteger s3 = fastPoint(x+1,y,  b)
		Dim As uInteger s4 = fastPoint(x+1,y+1,b)
		
		s1 = weightColors(s1, s3, weightX)
		s2 = weightColors(s2, s4, weightX)
		
		ret = weightColors(s1, s2, weightY)
		
	Case SI_COSINE
		' Use a cosine function to interpolate between values
		Dim As Double x = (b->width-1)*frac(sx)
		Dim As Double y = (b->height-1)*frac(sy)
		
		' I think this should work (should start at 1.0 when the input weight is 0, and go to 0 when it is 1.0)
		Dim As Double weightX = cos( frac(x) * _pi )
		Dim As Double weightY = cos( frac(y) * _pi )
		
		x = CInt(x)
		y = CInt(y)
		
		' Don't sample past the end of the texture
		If x >= b->width Then
			x = b->width-1
		Endif
		If y >= b->height Then
			y = b->height-1
		Endif
		
		Dim As uInteger s1 = fastPoint(x,  y,  b)
		Dim As uInteger s2 = fastPoint(x,  y+1,b)
		Dim As uInteger s3 = fastPoint(x+1,y,  b)
		Dim As uInteger s4 = fastPoint(x+1,y+1,b)
		
		s1 = weightColors(s1, s3, weightX)
		s2 = weightColors(s2, s4, weightX)
		
		ret = weightColors(s1, s2, weightY)
		
	End Select
        
        Return ret
End Function

' Shade a texture sample
Function shadePixel( ByVal colour As UInteger, ByVal shade As uByte ) As UInteger
        Dim As tPixel c1
        Dim As UInteger r,g,b,a
        
        c1.value = colour
        
        r = c1.r-(255-shade)
        g = c1.g-(255-shade)
        b = c1.b-(255-shade)
        a = c1.a-(255-shade)
        
        r = IIF(r > 255, 0, r)
        g = IIF(g > 255, 0, g)
        b = IIF(b > 255, 0, b)
        a = IIF(a > 255, 0, a)
        
        Return rgba(r, g, b, a)
End Function

' Do the raycasting
type raycaster
	' data from files
	map		As gameMap = gameMap(10,10)
	atlas		As textureAtlas
	
	' configuration
	renderW 	As Integer
	renderH 	As Integer
	
	renderScale	As Integer
	
	rayStep		As Double = 0.05
	
	playerX		As Double
	playerY		As Double
	playerA		As Double
	
	FOV		As Double = _pi/4
	
	farPlane	As Double = 2
	nearPlane	As Double = 0.01
	
	drawDistance	As Double = 20
	
	drawFloor	As Boolean = true
	
	' Timing
	frameTime	As Double
	frameRate	As Double
	
	' Image buffers
	screenBuffer	As fb.image Ptr
	
	' Constructor to initialise the screen buffer
	Declare Constructor ( ByVal As Integer, ByVal As Integer, ByVal As Integer = 1 )
	Declare Destructor ()
	
	Declare Sub draw()
	Declare Sub update()
end type

Constructor raycaster ( ByVal w As Integer, ByVal h As Integer, ByVal s As Integer = 1 )
	' Set our rendering context
	If s > 1 Then
		this.renderScale = s
	Else
		this.renderScale = 1
	Endif
	
	this.renderW = (w/this.renderScale)
	this.renderH = (h/this.renderScale)
	
	' Initialise the buffer we will draw to
	If this.screenBuffer <> 0 Then
		ImageDestroy(this.screenBuffer)
		this.screenBuffer = 0
	Endif
	
	this.screenBuffer = ImageCreate( w, h )
End Constructor

Destructor raycaster ()
	If this.screenBuffer <> 0 Then
		ImageDestroy(this.screenBuffer)
		this.screenBuffer = 0
	Endif
End Destructor

Sub raycaster.draw()
	' Clear the buffer
	Line this.screenBuffer, (0,0)-(this.renderW, this.renderH), rgb(0,0,0), BF
	
	' Render the floor
	' Unlike the raycasting code I haven't fully wrapped my head around this yet
	If this.drawFloor Then
		' Grab the current floor texture
		this.atlas.setTexture( this.map.segment( CInt(playerX), CInt(playerY) ).textureID )
		
		' Calculate the fustrum
		Dim As Double FarX1 = PlayerX + sin( PlayerA - (FOV/2) ) * farPlane
		Dim As Double FarY1 = PlayerY + cos( PlayerA - (FOV/2) ) * farPlane
		
		Dim As Double FarX2 = PlayerX + sin( PlayerA + (FOV/2) ) * farPlane
		Dim As Double FarY2 = PlayerY + cos( PlayerA + (FOV/2) ) * farPlane
		
		Dim As Double NearX1 = PlayerX + sin( PlayerA - (FOV/2) ) * nearPlane
		Dim As Double NearY1 = PlayerY + cos( PlayerA - (FOV/2) ) * nearPlane
		
		Dim As Double NearX2 = PlayerX + sin( PlayerA + (FOV/2) ) * nearPlane
		Dim As Double NearY2 = PlayerY + cos( PlayerA + (FOV/2) ) * nearPlane
		
		' Render the texture projection
		For y As Integer = 0 to renderH/2
			Dim As Double sampleDepth = y/(renderH/2)
			
			Dim As Double startX = (farX1-nearX1) / SampleDepth + nearX1
			Dim As Double startY = (farY1-nearY1) / SampleDepth + nearY1
			
			Dim As Double endX = (farX2-nearX2) / SampleDepth + nearX2
			Dim As Double endY = (farY2-nearY2) / SampleDepth + nearY2
			
			For x As Integer = 0 to renderW
				Dim As Double sampleWidth = x/renderW
				
				Dim As Double sampleX = (endX - startX) * sampleWidth + startX
				Dim As Double sampleY = (endY - startY) * sampleWidth + startY
				
				Dim As UInteger sample = sampleTexture( abs(sampleX), abs(sampleY), this.atlas.texture, SI_NEAREST )
				Dim As UInteger shade = 128+(128*sampleDepth)
				
				Line screenBuffer, (x*renderScale,(y + (renderH/2))*renderScale)-Step(this.renderScale, this.renderScale), _
					shadePixel(sample, shade), BF
			Next
		Next
	Endif
	
	' Cast rays and render to the buffer
	For x As Double = 0 to this.renderW
		' Variables we need
		Dim As Boolean	hitWall
		Dim As Double	distanceToWall
		
		Dim As Double	sampleX
		Dim As Double	sampleY
		
		' For each column calculate the ray angle
                Dim As Double	rayAngle = (this.PlayerA - this.FOV/2) + (x/this.renderW) * this.FOV
                
		' Unit vector the ray will run along
		Dim As Double	eyeX = sin( rayAngle )
		Dim As Double	eyeY = cos( rayAngle )
		
		' The info about the point on the map the ray landed in
		Dim As mapSegment Ptr	mapSegment
		
		' Extend the ray from the viewer
		Do Until hitWall or ( distanceToWall > this.drawDistance )
			distanceToWall += this.rayStep
			
			' Calculate the coordinates of the ray, and throw away the integer
			Dim As Integer testX = this.PlayerX + EyeX * distanceToWall
                        Dim As Integer testY = this.PlayerY + EyeY * distanceToWall
                        
                        ' Check if the ray is in bounds
                        If ( testX < 0 ) or ( testX > this.map.mapW ) or _
                           ( testY < 0 ) or ( testY > this.map.mapH ) Then
                           
                        	hitWall = true
                        	distanceToWall = this.drawDistance
                        Else
                        	mapSegment = @this.map.segment( testX, testY)
                        	
                        	If mapSegment->solid Then
                        		' This is a solid wall
                        		hitWall = true
                        		
                        		' Sample the texture
		                        Dim As Double TestPointX = PlayerX + EyeX * DistanceToWall
		                        Dim As Double TestPointY = PlayerY + EyeY * DistanceToWall
		                        
		                        Dim As Double textureX = TestPointX - TestX
		                        Dim As Double textureY = TestPointY - TestY
		                        
		                        ' This is a hack, there is a smart way to do this but it works
		                        ' acceptably. This will result in mirrored textures on some faces but IDC right now
		                        If abs(textureX) > abs(textureY) Then
		                        	sampleX = textureY
		                        Else
		                        	sampleX = TestPointX - TestX
		                        Endif
		                        
		                        ' Center the texture on the face
		                        sampleX += 0.5
                        	Endif
                        Endif
		Loop
		
		' Draw the column of the buffer that this ray corresponds to
		Dim As uByte	shade
		Dim As uInteger	wallColor
		Dim As uInteger	outputPixel
		
		' Calculate distance to ceiling and floor in screen space
                Dim As Integer Ceiling = (this.renderH/2)-(this.renderH/distanceToWall)
                Dim As Integer Floor = this.renderH-Ceiling
                
                For y As Integer = 0 to this.renderH
			If y < Ceiling Then
				' This is the sky, leave it blank for now
				outputPixel = rgb( 0, 0, 0 )
				
			ElseIf y > Floor Then
				' This is floor, shade it with a gradient for now
				shade = 255-(255*(this.renderH/y))
				
				If drawFloor then
					outputPixel = rgb(255,0,255)
				Else
					outputPixel = rgb( shade, shade, shade )
				Endif
				
			Else
				' This is the wall, calculate the shading depending on distance to the wall
				shade = 255-(255*(distanceToWall/drawDistance))
				
				' Calculate the other texture coordinate
				SampleY = ((y-ceiling)/(this.renderH-(ceiling*2)))
				
				' Set the texture atlas
				this.atlas.setTexture( mapSegment->textureID )
				
				' Sample the texture
				outputPixel = sampleTexture( sampleX, sampleY, this.atlas.texture, SI_NEAREST )
				outputPixel = shadePixel( outputPixel, shade )
			Endif
			
			' Draw to the buffer
			If outputPixel <> rgb(255,0,255) Then
				Line this.screenBuffer, (x*this.renderScale,y*this.renderScale)-STEP(this.renderScale, this.renderScale), outputPixel, BF
			Endif
                Next
	Next
End Sub

Sub raycaster.update()
	' Update the player position
	
	' Calculate frame delta and framerate
	this.frameTime = timer-this.frameTime
        this.frameRate = 1/this.frameTime
        
        ' Store the player's position
        Dim As Double oldPlayerX = PlayerX
        Dim As Double oldPlayerY = PlayerY
        
        ' Look left/right
        If Multikey(fb.SC_A) Then
                this.playerA -= 1 * frameTime
        Endif
        If Multikey(fb.SC_D) Then
                this.playerA += 1 * frameTime
        Endif
        
        ' Move forward/back
        If Multikey(fb.SC_W) Then
                this.playerX += sin(PlayerA) * 5.0 * frameTime
                this.playerY += cos(PlayerA) * 5.0 * frameTime
        Endif
        If Multikey(fb.SC_S) Then
                this.playerX -= sin(PlayerA) * 5.0 * frameTime
                this.playerY -= cos(PlayerA) * 5.0 * frameTime
        Endif
        
        ' strafe left/right
        If Multikey(fb.SC_Q) Then
                this.playerX += sin(PlayerA-(_pi/2)) * 2.0 * frameTime
                this.playerY += cos(PlayerA-(_pi/2)) * 2.0 * frameTime
        Endif
        If Multikey(fb.SC_E) Then
                this.playerX += sin(PlayerA+(_pi/2)) * 2.0 * frameTime
                this.playerY += cos(PlayerA+(_pi/2)) * 2.0 * frameTime
        Endif
        
        ' If the player is outside the map then reset the position to before they moved
        If (this.playerX < 0) or (this.playerX > this.map.mapW) or _
           (this.playerY < 0) or (this.playerY > this.map.mapH) Then
           
        	this.playerX = oldPlayerX
        	this.playerY = oldPlayerY
        Endif
        
        ' If the player is colliding with a wall then reset the position to before they moved
        If this.map.segment( CInt(this.playerX), CInt(this.playerY) ).solid Then
        	this.playerX = oldPlayerX
        	this.playerY = oldPlayerY
        Endif
        
        ' Track the time we last update the inputs
        frameTime = timer
End Sub

