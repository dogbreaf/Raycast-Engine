#include "textureAtlas.bi"
#include "map.bi"

#define __XRES 800
#define __YRES 480

' Variables
Dim As textureAtlas	uAtlas
Dim As gameMap		uMap = gameMap(32,32)

Dim As Integer		selectedTexture
Dim As Integer		editX, editY

Dim As String		fileName

' Initialisation
ScreenRes __XRES,__YRES,32

' Load file specified on the commandline
If Command(1) <> "" Then
	uMap.load( Command(1) )
	fileName = Command(1)
Else
	uMap = gameMap(32,32)
	fileName = "untitled.dat"
Endif

If Command(2) <> "" Then
	uAtlas.loadTextures( Command(2) )
Endif

' Main Loop
Do
	ScreenLock
	Line (0,0)-(__XRES,__YRES), rgb(30,30,30), BF
	
	' Draw the texture atlas
	Put ( __XRES - uAtlas.atlas->width - 16, 64 ), uAtlas.atlas, PSET
	Put ( __XRES - uAtlas.atlas->width - 16, 16 ), uAtlas.texture, PSET
	
	uAtlas.setTexture( uMap.segment(editX, editY).textureID )
	Put ( __XRES - uAtlas.atlas->width + 32, 16 ), uAtlas.texture, PSET
	
	' Draw the map top-down
	For y As Integer = 0 to uMap.mapH
		For x As Integer = 0 to uMap.mapW
			If uMap.segment(x,y).solid Then
				Line ( 16 + ( x*8 ), 16 + ( y*8 ) )-Step(8,8), rgb(255,255,255), BF
				
				uAtlas.setTexture( uMap.segment(x,y).textureID )
				Put ( 16 + (x*8), 16 + (y*8) ), uAtlas.texture, (8,8)-STEP(8,8), PSET
			Else
				Line ( 16 + ( x*8 ), 16 + ( y*8 ) )-Step(8,8), rgb(0,0,0), BF
			Endif
		Next
	Next
	
	' Draw the selection box
	Line ( 16 + ( editX*8 ), 16 + ( editY*8 ) )-Step(8,8), rgb(255,0,0), B
	ScreenUnLock
	
	' Get inputs
	
	' Resize the map
	If Multikey(fb.SC_CONTROL) and Multikey(fb.SC_R) Then
		Do:Sleep 1,1:Loop Until InKey() = ""
		
		Line (0,0)-(__XRES, 8), rgb(0,0,0), BF
		
		Dim As Integer inX, inY
		
		Locate 1,1
		Input "Map size (w,h) > ", inX, inY
		
		If (inX > 1) and (inY > 1) Then
			Line (0,0)-(__XRES, 8), rgb(0,0,0), BF
			
			Locate 1,1
			Print "Changes will be lost, are you sure? Y/N"
			
			Do
				Sleep 1,1
				
				If Multikey(fb.SC_Y) Then
					uMap = gameMap(inX,inY)
				Endif
			Loop Until inKey() <> ""
		Endif
	Endif
	
	' Save the map
	If Multikey(fb.SC_CONTROL) and Multikey(fb.SC_S) Then
		Do:Sleep 1,1:Loop Until InKey() = ""
		
		Dim As String fname
		
		Line (0,0)-(__XRES, 8), rgb(0,0,0), BF
		Locate 1,1
		Print "File Name? (" & fileName & ") > ";
		Input "", fname
		
		If fname <> "" Then
			fileName = fname
		Endif
		
		uMap.save(fileName)
		
		Line (0,0)-(__XRES, 8), rgb(0,0,0), BF
		Locate 1,1
		Print "Saved as " & fileName & " (Probably...)"
		
		Sleep 1000
	Endif
	
	' Select a texture
	If Multikey(fb.SC_PAGEUP) Then
		selectedTexture += 1
		Do:Sleep 1,1:Loop Until not Multikey(fb.SC_PAGEUP)
	EndIf
	If Multikey(fb.SC_PAGEDOWN) Then
		SelectedTexture -= 1
		Do:Sleep 1,1:Loop Until not Multikey(fb.SC_PAGEDOWN)
	Endif
	
	If selectedTexture < 0 Then
		selectedTexture = 0
	ElseIf selectedTexture > ( uAtlas.atlas->width/uAtlas.textureSize ) * ( uAtlas.atlas->height/uAtlas.textureSize ) Then
		selectedTexture = ( uAtlas.atlas->width/uAtlas.textureSize ) * ( uAtlas.atlas->height/uAtlas.textureSize )
	Endif
	
	uAtlas.setTexture(selectedTexture)
	
	' Edit
	If Multikey(fb.SC_W) Then
		editY -= 1
		Do:Sleep 1,1:Loop Until not Multikey(fb.SC_W)
	EndIf
	If Multikey(fb.SC_S) Then
		editY += 1
		Do:Sleep 1,1:Loop Until not Multikey(fb.SC_S)
	Endif
	If Multikey(fb.SC_A) Then
		editX -= 1
		Do:Sleep 1,1:Loop Until not Multikey(fb.SC_A)
	EndIf
	If Multikey(fb.SC_D) Then
		editX += 1
		Do:Sleep 1,1:Loop Until not Multikey(fb.SC_D)
	Endif
	
	If editX < 0 Then
		editX = 0
	ElseIf editX > uMap.mapW Then
		editX = uMap.mapW
	Endif
	
	If editY < 0 Then
		editY = 0
	ElseIf editY > uMap.mapH Then
		editY = uMap.mapH
	Endif
	
	'
	If Multikey(fb.SC_Q) Then
		uMap.segment(editX, editY).solid = 0
		uMap.segment(editX, editY).textureID = 0
		
		Sleep 1,1
	EndIf
	If Multikey(fb.SC_E) Then
		uMap.segment(editX, editY).solid = 1
		uMap.segment(editX, editY).textureID = selectedTexture
		
		Sleep 1,1
	Endif
	
	Sleep 1,1
Loop Until Multikey(1)

