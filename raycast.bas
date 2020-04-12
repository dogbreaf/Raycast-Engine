#include "headers/errors.bi"

#include "headers/imagedata.bi"
#include "headers/textureAtlas.bi"
#include "headers/map.bi"
#include "headers/raycast.bi"

#define __XRES 800
#define __YRES 600

ScreenRes __XRES,__YRES,32

Dim As raycaster	test = raycaster(__XRES-20,__YRES-20,IIF(__XRES > 400, 4, 2))

If command(1) <> "" Then
	logError( test.map.load(command(1)), __errorTrace, true )
	logError( test.atlas.loadAtlas(command(2)), __errorTrace, true )
Else
	logError( test.map.load("data/test.dat"), __errorTrace, true )
	logError( test.atlas.loadAtlas("data/test.atlas.dat"), __errorTrace, true )
Endif

test.getMapSettings()

Do
	ScreenLock
		Line (0,0)-(__XRES,__YRES), rgb(40,40,40), BF
		
		put (10,10), test.screenBuffer, ALPHA
		
		draw String (11,11), "FPS : " & CInt( test.frameRate ), rgb(120,255,10)
	ScreenUnLock
	
	logError(test.draw(), __errorTrace, true)
	logError(test.update(), __errorTrace, true)

	
	If Multikey(fb.SC_F12) Then
                Line (0,__YRES/2)-step(__XRES, 10), rgb(0,0,0), BF
                Draw String (__XRES/2 - 80, __YRES/2 + 2), "Taking screenshot..."
                
		logError(test.screenshot(3840,2560), __errorTrace, true)
	Endif
        
        ' Save a low-res screenshot with a depth buffer
        If Multikey(fb.SC_F11) Then
                Line (0,__YRES/2)-step(__XRES, 10), rgb(0,0,0), BF
                Draw String (__XRES/2 - 80, __YRES/2 + 2), "Taking screenshot..."
                
                Dim As String fname = Hex( Rnd()*(2^32) ) & Hex( Rnd()*(2^32) )
                
                ' Save the rendered buffer
                BSave "IMG_" & fname & "_BUFFER.bmp", test.screenBuffer
                
                ' Render the depth buffer as an image
                Dim As Any Ptr depthBuffer = ImageCreate( test.renderW*test.renderScale, test.renderH*test.renderScale )
                
                For y As Integer = 0 to test.renderH
                        For x As Integer = 0 to test.renderW
                                Dim As uByte depth = 255-255*(test.depthBuffer(x,y)/test.drawDistance)
                                
                                Line depthBuffer, (x*test.renderScale,y*test.renderScale)-step(test.renderScale,test.renderScale), _
                                        rgb(depth, depth, depth), BF
                        Next
                Next
                
                BSave "IMG_" & fname & "_DEPTH.bmp", depthBuffer
                
                ImageDestroy(depthBuffer):depthBuffer = 0
                
                Sleep 500,1
        Endif
	
	Sleep 1,1
Loop Until Multikey(1)

