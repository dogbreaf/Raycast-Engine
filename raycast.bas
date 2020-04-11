#include "headers/errors.bi"

#include "headers/imagedata.bi"
#include "headers/textureAtlas.bi"
#include "headers/map.bi"
#include "headers/raycast.bi"

ScreenRes 800,600,32

Dim As raycaster	test = raycaster(780,580,4)

If command(1) <> "" Then
	logError( test.map.load(command(1)), __errorTrace, true )
	logError( test.atlas.loadAtlas(command(2)), __errorTrace, true )
Else
	logError( test.map.load("data/test.dat"), __errorTrace, true )
	logError( test.atlas.loadAtlas("data/test.atlas.dat"), __errorTrace, true )
Endif

test.fogColor = rgb(200,210,180)

test.playerX = 6.5
test.playerY = 3.5
test.playerA = 0

' A burning trash can 
logError( test.map.addObject( 1.5, 1.5,,, 2048 ), __errorTrace, true )

' Cones
logError( test.map.addObject( 58.5, 9,,, 59 ), __errorTrace, true )
logError( test.map.addObject( 58.5, 10,,, 59 ), __errorTrace, true )
logError( test.map.addObject( 58.5, 11,,, 59 ), __errorTrace, true )

For i As Integer = 0 to 15
	' Add 15 trees
	' 21,2 47,7
	Dim As Double x = Rnd()*(47-21) + 21
	Dim As Double y = Rnd()*(7-2) + 2
	
	logError( test.map.addObject( x + 0.5, y + 0.5,,, 2055 ), __errorTrace, true )
Next

Do
	ScreenLock
		Line (0,0)-(800,600), rgb(40,40,40), BF
		
		put (10,10), test.screenBuffer, PSET
		
		draw String (11,11), "FPS : " & CInt( test.frameRate ), rgb(120,255,10)
	ScreenUnLock
	
	logError(test.draw(), __errorTrace, true)
	logError(test.update(), __errorTrace, true)
	
	If Multikey(fb.SC_UP) Then
		test.drawDistance += 0.5
		sleep 100,1
	Endif
	If Multikey(fb.SC_DOWN) Then
		test.drawDistance -= 0.5
		sleep 100,1
	Endif
	
	If Multikey(fb.SC_F12) Then
		Print "Taking screenshot..."
		
		Dim As Integer cx,cy,cs
		Dim As Integer resX = 3840, resy = 2160
		
		cx = test.renderW
		cy = test.renderH
		cs = test.renderScale
		
		test.renderW = resX
		test.renderH = resY
		test.renderScale = 1
		
		If test.screenBuffer <> 0 Then
			ImageDestroy(test.screenBuffer):test.screenBuffer = 0
		Endif
		test.screenBuffer = ImageCreate(resX,resY)
		
		ReDim test.depthBuffer(resX, resY) As Double
		
		test.draw()
		
		Randomize Timer
		
		BSave "Screenshot" & Hex(Rnd()*(2^32)) & ".bmp", test.screenBuffer
		
		test.renderW = cx
		test.renderH = cy
		test.renderScale = cs
		
		If test.screenBuffer <> 0 Then
			ImageDestroy(test.screenBuffer):test.screenBuffer = 0
		Endif
		test.screenBuffer = ImageCreate(cx*cs,cy*cs)
		
		ReDim test.depthBuffer(cx,cy)
		
		Print "Done."
		Sleep 100,1
	Endif
	
	Sleep 1,1
Loop Until Multikey(1)

