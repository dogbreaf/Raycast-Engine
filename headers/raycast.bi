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
	SI_SINE
End Enum

' Much faster than point()
Function fastPoint( ByVal x As Integer, ByVal y As Integer, ByVal b As fb.Image Ptr ) As UInteger
	Dim As UInteger Ptr ret
	
	If ( x < b->width ) and ( y < b->height ) Then
		ret = ( cast(Any Ptr, b) + sizeOf(fb.Image) + b->pitch * y + b->bpp * x )
	Else
		Return 0
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

		Dim As uInteger s1 = fastPoint(x,  y,  b)
		Dim As uInteger s2 = fastPoint(x,  y+1,b)
		Dim As uInteger s3 = fastPoint(x+1,y,  b)
		Dim As uInteger s4 = fastPoint(x+1,y+1,b)
		
		s1 = weightColors(s1, s3, weightX)
		s2 = weightColors(s2, s4, weightX)
		
		ret = weightColors(s1, s2, weightY)
		
	Case SI_SINE
		' Use a cosine function to interpolate between values
		Dim As Double x = (b->width-1)*frac(sx)
		Dim As Double y = (b->height-1)*frac(sy)
		
		' I think this should work (should start at 1.0 when the input weight is 0, and go to 0 when it is 1.0)
		Dim As Double weightX = sin( frac(x) * _pi )
		Dim As Double weightY = sin( frac(y) * _pi )
		
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
        
        ret = ret and rgba(255,255,255,0)
        ret += rgba(0,0,0,255)
        
        Return ret
End Function

' Shade a texture sample by a certain amount and colour it with the background color
Function shadePixel( ByVal colour As UInteger, ByVal shade As uByte, ByVal fog As UInteger = rgb(0,0,0)) As UInteger
        Dim As tPixel c1
        Dim As tPixel c2
        Dim As UInteger r,g,b,a
        
        c1.value = colour
        c2.value = fog

	r = c1.r*(shade/255)
	g = c1.g*(shade/255)
	b = c1.b*(shade/255)
	a = c1.a*(shade/255)
		
	If fog <> 0 Then
		c2.r = c2.r*((255-shade)/255)
		c2.g = c2.g*((255-shade)/255)
		c2.b = c2.b*((255-shade)/255)
		c2.a = c2.a*((255-shade)/255)
		
		r += c2.r
		g += c2.g
		b += c2.b
		a += c2.a
	Endif
        
        r = IIF(r > 255, 0, r)
        g = IIF(g > 255, 0, g)
        b = IIF(b > 255, 0, b)
        a = IIF(a > 255, 0, a)
        
        Return rgba(r, g, b, a)
End Function

' Calculate the angle between two points
Function directionTo( ByVal x1 As Double, ByVal y1 As Double, ByVal x2 As Double, ByVal y2 As Double ) As Double
	Dim As Double a,b
	
	Dim As Double ret

	b = abs(x1-x2)
	a = abs(y1-y2)

	If x2 < x1 and y2 < y1 then
		ret = atn( b/a )
		ret += _pi
		
	ElseIf x2 > x1 and y2 > y1 then
		ret = atn( b/a )
		
	ElseIf x2 > x1 and y2 < y1 then
		ret = atn( a/b )
		ret -= _pi/2 + _pi	' Not sure if the +pi is supposed to be there but it fixes a bug
		
	ElseIf x2 < x1 and y2 > y1 then
		ret = atn( a/b )
		ret += _pi/2 + _pi	' Not sure if the +pi is supposed to be there but it fixes a bug
		
	Else
		ret = 0
	Endif

	Return ret
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
	
	fogColor	As ULong
        
        interpolation   As sampleInterpolation = SI_NEAREST
        
        ' temporary fix for flickering floor
        ' Has a big performance penalty
        floorFix        As Boolean = true
	
	' Timing
	frameTime	As Double
	frameRate	As Double
	
	' Image buffers
	screenBuffer	As fb.image Ptr
	
	' The depth buffer
	depthBuffer(Any, Any)	As Double
	
	' Constructor to initialise the screen buffer
	Declare Constructor ( ByVal As Integer, ByVal As Integer, ByVal As Integer = 1 )
	Declare Destructor ()
        
        Declare Function getMapSettings() As errorCode
	
	Declare Function draw() As errorCode
	Declare Function update() As errorCode
        
        Declare Function screenshot( ByVal As Integer, ByVal As Integer, ByVal As String = "" ) As errorCode
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
	
	' Initialise the depth buffer
	ReDim this.depthBuffer(this.renderW, this.renderH) As Double
End Constructor

Destructor raycaster ()
	If this.screenBuffer <> 0 Then
		ImageDestroy(this.screenBuffer)
		this.screenBuffer = 0
	Endif
End Destructor

Function raycaster.getMapSettings() As errorCode
        this.fogColor = this.map.fogColor
        this.drawDistance = this.map.fogDistance
        
        If this.drawDistance < 4 Then
                this.drawDistance = 4
        Endif
        
        this.playerX = this.map.playerX
        this.playerY = this.map.playerY
        this.playerA = this.map.playerA
        
        Return E_NO_ERROR
End Function

Function raycaster.draw() As errorCode
	Dim As errorCode retCode
	
	' Make sure the buffer exists
	If this.screenBuffer = 0 Then
		Return E_NO_BUFFER
	Endif
	
	' Clear the buffer
	Line this.screenBuffer, (0,0)-(this.renderW*this.renderScale, this.renderH*this.renderScale), this.fogColor, BF
	
	' Render the floor
	' Unlike the raycasting code I haven't fully wrapped my head around this yet
	If this.drawFloor Then		
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
				
				Dim As Integer mapX = CInt(sampleX)
				Dim As Integer mapY = CInt(sampleY)
                                
                                ' Fix the flickering floor textures
                                If floorFix Then
                                        this.atlas.previousID = -1
                                Endif
				
				' Grab the current floor texture
				If (mapX < this.map.mapW) and (mapY < this.map.mapH) and (mapX > 0) and (mapY > 0) Then
					If this.map.segment( mapX, mapY).solid = 0 Then
						retCode = this.atlas.setTexture( this.map.segment( mapX, mapY).textureID )
					Else
						retCode = this.atlas.setTexture(0)
					Endif
				Else
					retCode = this.atlas.setTexture( 0 )
				Endif
				
				logError(retCode, __errorTrace, false)
				
				' Sample the texture
				Dim As UInteger sample = sampleTexture( abs(sampleX+0.5), abs(sampleY+0.5), this.atlas.texture, interpolation )
				
				' Calculate the distance from the player
				Dim As Double distance = sqr( (( playerX-sampleX ) ^ 2) + (( playerY-sampleY ) ^ 2) )
				
				' Shade it accordingly
				Dim As UInteger shade = 255-(255*(distance/drawDistance))
				
				If sampleDepth > drawDistance Then
					shade = 0
				Endif
                                
                                ' Update the depth buffer
                                If (UBound(this.depthBuffer, 1) < x) or (UBound(this.depthBuffer, 2) < y) Then
                                        Return E_UNKNOWN
                                Endif
                                this.depthBuffer(x,y) = distance
				
				' Put it on the buffer
				Line screenBuffer, (x*renderScale,(y + (renderH/2))*renderScale)-Step(this.renderScale, this.renderScale), _
					shadePixel(sample, shade, this.fogColor), BF
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
                	' Check that the depth buffer is large enough before we start filling it
                	If (UBound(this.depthBuffer, 1) < x) or (UBound(this.depthBuffer, 2) < y) Then
                		Return E_UNKNOWN
                	Endif
                	
                	' Draw the appropriate thing
			If y < Ceiling Then
				' This is the sky, leave it blank for now
				outputPixel = this.fogColor
				
				' Update the depth buffer
				depthBuffer(x,y) = this.drawDistance
				
			ElseIf y > Floor Then
                                shade = 255-(255*(this.renderH/y))
                                
				' The floor may have already been drawn with a texture
				If drawFloor then
					outputPixel = rgb(255,0,255)
				Else
                                        ' Shade the floor according to depth
					outputPixel = rgb( shade, shade, shade )
				Endif
                                
                                ' Fix the depth buffer, the distance calculated before seems to be buggy
                                depthBuffer(x,y) = ((255-shade)/255)*drawDistance
                                
                                ' The floor can't be further away than the wall, thats impossible
                                If depthBuffer(x,y-1) < depthBuffer(x,y) Then
                                        depthBuffer(x,y) = depthBuffer(x,y-1)
                                Endif
				
			ElseIf distanceToWall >= drawDistance Then
				outputPixel = this.fogColor
				
				' Update the depth buffer
				depthBuffer(x,y) = this.drawDistance
				
			Else				
				' This is the wall, calculate the shading depending on distance to the wall
				shade = 255-(255*(distanceToWall/drawDistance))
				
				' Calculate the other texture coordinate
				SampleY = ((y-ceiling)/(this.renderH-(ceiling*2)))
				
				' Set the texture atlas
				retCode = this.atlas.setTexture( mapSegment->textureID )
				logError(retCode, __errorTrace, false)
				
				' Sample the texture
				outputPixel = sampleTexture( sampleX, sampleY, this.atlas.texture, interpolation )
				
				' Shade it if its not "transparent"
                                If outputPixel <> rgb(255,0,255) Then
                                        ' Applying shade if it is transparent makes it not transparent
                                        OutputPixel = shadePixel( outputPixel, shade, this.fogColor )
                                        
                                        ' Update the depth buffer
                                        depthBuffer(x,y) = distanceToWall
                                Else
                                        ' If the pixel is transparent but above the middle of the screen 
                                        ' the depth should be at the draw distance
                                        If y < renderH/2 Then
                                                depthBuffer(x,y) = drawDistance
                                        Endif
                                Endif
			Endif
			
			' Draw to the buffer
			If outputPixel <> rgb(255,0,255) Then
				Line this.screenBuffer, (x*this.renderScale,y*this.renderScale)-STEP(this.renderScale, this.renderScale), outputPixel, BF
			Endif
                Next
	Next
	
	' Render any objects
	If UBound(this.map.mObject) > -1 Then
		For i As Integer = 0 to UBound(this.map.mObject)
			' Create a handy pointer to the object
			Dim As mapObject Ptr workingObject = @this.map.mObject(i)
			
			' Calculate the distance to the object
			Dim As Double vecX = workingObject->posX - this.playerX
			Dim As Double vecY = workingObject->posY - this.playerY
			
			Dim As Double distanceFromPlayer = sqr( (vecX^2) + (vecY^2) )
			
			' Calculate if the object is within the FOV
			Dim As Double eyeX = sin(this.playerA)
			Dim As Double eyeY = cos(this.playerA)
			
			Dim As Double objectAngle = directionTo( playerX, playerY, workingObject->posX, workingObject->posY )
			
			' Clamp the player angle to make the maths easier
			If playerA > 2*_pi Then
				playerA = 0
			Endif
			If playerA < 0 Then
				playerA = 2*_pi
			Endif
			
			' The angle we want is the difference between where the player is facing and the angle between the player and the object
			' i.e. it will be 0 when the player is looking directly at the object and move to +/- 2pi as they turn to either side
			objectAngle -= playerA
			
			' Draw the object if it is visible
			If ( distanceFromPlayer > 0.1 ) _
			   and ( distanceFromPlayer < this.drawDistance ) _
			   and abs(objectAngle) < (this.FOV/2) Then
			
				' Calculate the position of the object in screen space
				Dim As Double objectCeiling = ( renderH/2 ) - renderH / distanceFromPlayer
				Dim As Double objectFloor = renderH - objectCeiling
				
				Dim As Double objectHeight = (objectFloor-objectCeiling)*workingObject->height
				Dim As Double objectWidth = (objectFloor-objectCeiling)*workingObject->width
				
				' This might not be 100% perfect, dunno
				Dim As Double objectCenter =  0.5 + ((this.FOV/2) + objectAngle/this.FOV)*this.renderW
				
				For y As Integer = 0 to objectHeight
					For x As Integer = 0 to objectWidth
						' Sample the texture
						Dim As Double sampleX = x / objectWidth
						Dim As Double sampleY = y / objectHeight
						
						Dim As Integer objectColumn = objectCenter + x - (objectWidth/2)
						Dim As Integer pX = objectColumn
						Dim As Integer pY = objectCeiling + y
						
						this.atlas.setTexture( workingObject->textureID )
						
						Dim As tPixel sample
						sample.value = sampleTexture( sampleX, sampleY, this.atlas.texture, interpolation )
						
						' If it is not transparent and not off screen
						If (sample.r <> 255) and (sample.b <> 255) and (sample.g <> 0) and _
							(pX > 0) and (pY > 0) and (pX < renderW) and (pY < renderH) Then
							
							' Shade the object depending on distance
							Dim As UInteger shade = 255 - (255 * ( distanceFromPlayer/this.drawDistance ))
							
							sample.value = shadePixel( sample.value, shade, this.fogColor )
							
							' Check array bounds
							If (UBound(this.depthBuffer, 1) < pX) or (UBound(this.depthBuffer, 2) < pY) Then
								Return E_UNKNOWN
							Endif
							
							' Draw the object
							If distanceFromPlayer < this.depthBuffer(pX, pY) Then
								' The object is the closest thing so far
								this.depthBuffer(pX, pY) = distanceFromPlayer
							
								Line this.screenBuffer, (pX*renderScale, pY*this.renderScale)-step _
									(this.renderScale, this.renderScale), sample.value, BF
							Endif
						Endif
					Next
				Next
			Endif
		Next
	Endif
	
	Return E_NO_ERROR
End Function

Function raycaster.update() As errorCode
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
        
        '
        Return E_NO_ERROR
End Function

Function raycaster.screenshot( ByVal resX As Integer, ByVal resY As Integer, ByVal fname As String = "" ) As errorCode
        ' Take a super-sampled screenshot
        consolePrint("Taking screenshot...")
		
        Dim As Integer cx,cy,cs
        Dim As String fileName
        
        If fname <> "" Then
                fileName = fname
        Else
                Randomize Timer
                fileName = Command(0) & "_SCREENSHOT_" & Hex(Rnd()*(2^32)) & Hex(Rnd()*(2^32)) & ".bmp"
        Endif
        
        cx = this.renderW
        cy = this.renderH
        cs = this.renderScale
        
        this.renderW = resX
        this.renderH = resY
        this.renderScale = 1
        
        If this.screenBuffer <> 0 Then
                ImageDestroy(this.screenBuffer):this.screenBuffer = 0
        Endif
        this.screenBuffer = ImageCreate(resX,resY)
        
        If this.screenBuffer = 0 Then
                Return E_NO_BUFFER
        Endif
        
        ReDim this.depthBuffer(resX, resY) As Double
        
        If UBound( this.depthBuffer, 1 ) <> resX and UBound( this.depthBuffer, 2 ) <> resY Then
                Return E_RESIZE_FAILED
        Endif
        
        this.draw()

        BSave fileName, this.screenBuffer
        
        this.renderW = cx
        this.renderH = cy
        this.renderScale = cs
        
        If this.screenBuffer <> 0 Then
                ImageDestroy(this.screenBuffer):this.screenBuffer = 0
        Endif
        this.screenBuffer = ImageCreate(cx*cs,cy*cs)
        
        If this.screenBuffer = 0 Then
                Return E_NO_BUFFER
        Endif
        
        ReDim this.depthBuffer(cx,cy)
        
        If UBound( this.depthBuffer, 1 ) <> cx and UBound( this.depthBuffer, 2 ) <> cy Then
                Return E_RESIZE_FAILED
        Endif
        
        consolePrint "Done."
        
        Return E_NO_ERROR
End Function

