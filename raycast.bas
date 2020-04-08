#include "headers/textureAtlas.bi"
#include "headers/map.bi"
#include "headers/raycast.bi"

ScreenRes 640,480,32

Dim As raycaster	test = raycaster(620,460,2)

test.map.load("data/test.dat")
test.atlas.loadTextures( "data/texture.bmp" )

test.playerX = 6.5
test.playerY = 3.5
test.playerA = _pi

Do
	ScreenLock
		Line (0,0)-(640,480), rgb(40,40,40), BF
		
		put (10,10), test.screenBuffer, PSET
		
		draw String (11,11), "FPS : " & CInt( test.frameRate ), rgb(120,255,10)
	ScreenUnLock
	
	test.draw()
	test.update()
	
	Sleep 1,1
Loop Until Multikey(1)

