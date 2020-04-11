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

logError( test.map.addObject( 1.5, 1.5,,, 2048 ), __errorTrace, true )

logError( test.map.addObject( 12.5, 12.5,,, 2048 ), __errorTrace, true )
logError( test.map.addObject( 12.5, 13.5,,, 2048 ), __errorTrace, true )

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
		
		Print "Done."
		Sleep 100,1
	Endif
	
	Sleep 1,1
Loop Until Multikey(1)

