' Map editor window
'

type mapEditor
	' Pointers to the things we are editing
	uAtlas	As textureAtlas Ptr
	uMap	As gameMap Ptr
	
	' Editor vars	
	textureID		As Integer
	
	editX			As Integer
	editY			As Integer
	
	fileName		As String
	atlasFile		As String
        
        selectedObject          As Integer
        
        mapScale                As Integer = 8
	
	' Show the editor
	Declare Sub show()
	
	Declare Constructor()
end type

Sub mapEditor.show()
	Do
		ScreenLock		
		' Clear the screen
		Line (0,0)-(__XRES,__YRES), rgb(30,30,30), BF
	
		' Draw the texture atlas and texture previews
		Put (__XRES - uAtlas->atlas->width - 16, 64), uAtlas->atlas, PSET
		
		uAtlas->setTexture(textureID)
		scalePut (, __XRES - uAtlas->atlas->width - 16, 16, 32, 32, uAtlas->texture )
		
		Line (__XRES - uAtlas->atlas->width - 16 + uAtlas->textureX, 64 + uAtlas->textureY)-Step _
                        (uAtlas->textureSize,uAtlas->textureSize), rgb(0,255,0), B
		
		uAtlas->setTexture( uMap->segment(editX, editY).textureID )
		scalePut (, __XRES - uAtlas->atlas->width + 32, 16, 32, 32, uAtlas->texture )
		
		Line (__XRES - uAtlas->atlas->width - 16 + uAtlas->textureX, 64 + uAtlas->textureY)-Step _
                        (uAtlas->textureSize,uAtlas->textureSize), rgb(0,255,255), B

		' Draw some info 
		Draw String ( __XRES - uAtlas->atlas->width - 16 + 100, 14), "TextureID:   " & textureID
		Draw String ( __XRES - uAtlas->atlas->width - 16 + 100, 24), "Selected ID: " & uMap->segment(editX, editY).textureID
		
		Draw String ( __XRES - uAtlas->atlas->width - 16, 2 ), "Texture Atlas (Ctrl+A to edit)"
		
		Line ( __XRES - uAtlas->atlas->width - 32, 16 )-STEP(0,__YRES-32)
                
                ' Map info
                Line (__XRES - uAtlas->atlas->width - 16, __YRES-100)-(__XRES, __YRES), rgb(30,30,30), BF
                
                Draw String ( __XRES - uAtlas->atlas->width - 16, __YRES-100), _
                        "MapSize:      " & uMap->mapW & "x" & uMap->mapH
                        
                Draw String ( __XRES - uAtlas->atlas->width - 16, __YRES-90), _
                        "Player Start: " & uMap->PlayerX & "," & uMap->PlayerY & _
                        " (" & (uMap->playerA*(180/_pi)) & chr(248) & ")"
                        
                Draw String ( __XRES - uAtlas->atlas->width - 16, __YRES-80), _
                        "Fog Color:    "
                Draw String ( __XRES - uAtlas->atlas->width - 16, __YRES-70), _
                        "Fog Distance: " & uMap->fogDistance
                        
                Line ( __XRES - uAtlas->atlas->width - 16 + 112, __YRES-80)-step(32,8), uMap->fogColor, BF
		
		'
		Draw String ( 16, 2 ), "Map"
		
		Draw String (100, 2), "Pos: " & editX & ", " & editY
		
		' Draw the map top-down
		For y As Integer = 0 to uMap->mapH
			For x As Integer = 0 to uMap->mapW
				uAtlas->previousID = -1
				
				logError(uAtlas->setTexture( uMap->segment(x,y).textureID ), __errorTrace, false)
				scalePut(, 16+(x*mapScale), 16+(y*mapScale), mapScale, mapScale, uAtlas->texture )
					
				If uMap->segment(x,y).solid Then
					Line ( 16 + ( x*mapScale ), 16 + ( y*mapScale ) )-Step(mapScale,mapScale), rgb(255,0,120), B
				Endif
			Next
		Next
                
                ' Draw the selection box
		Line ( 16 + ( editX*mapScale ), 16 + ( editY*mapScale ) )-Step(mapScale,mapScale), rgb(255,255,0), B
                
                ' Draw object markers
                For i As Integer = 0 to UBound(uMap->mObject)
                        Dim As mapObject Ptr wObj = @uMap->mObject(i)
                        
                        Circle (16+wObj->posX*mapScale, 16+wObj->posY*mapScale), mapScale/2, rgb(0,255,120)
                Next
                
                ' Draw Player marker
                Circle (16+uMap->playerX*mapScale, 16+uMap->playerY*mapScale), mapScale/3, rgb(120,255,80),,,, F
                Line (16+uMap->playerX*mapScale, 16+uMap->playerY*mapScale)-step _
                     (sin(uMap->playerA)*mapScale, cos(uMap->playerA)*mapScale), rgb(255,255,255)
                
                ' Draw the list of objects
                Line (16, __YRES-130)-(__XRES - uAtlas->atlas->width - 64, __YRES-130), rgb(255,255,255)
                
                Draw String ( 16, __YRES-126 ), "Objects (Ctrl+O to add)"
                
                Dim As Integer objectCount = UBound( uMap->mObject )
                Dim As String objectList(objectCount)
                
                For i As Integer = 0 to objectCount
                        objectList(i) = i & " " & uMap->mObject(i).posX & "," & _
                                uMap->mObject(i).posY & " Texture: " & _
                                uMap->mObject(i).textureID
                Next
                selectList( 16, __YRES-116, 256, 100, objectList(), selectedObject)
                
                If UBound(uMap->mObject) > -1 Then
                        uAtlas->setTexture(uMap->mObject(selectedObject).textureID)
                        scalePut(, 288, __YRES-116, 32, 32, uAtlas->texture )
		Else
                        Line ( 288, __YRES-116)-step(32, 32), rgb(40,40,40), BF
                Endif
                
		ScreenUnlock

		' Input polling
		If userHotkey( fb.SC_A, fb.SC_CONTROL ) Then
			editAtlas(uAtlas, atlasFile)
			
			Do:Sleep 1,1:Loop Until not Multikey(1)
		Endif
		
		If userHotkey( fb.SC_R, fb.SC_CONTROL ) Then
			' Resize the map
			blackBar()
		
			Dim As Integer inX, inY
			
			Input "Map size (w,h) > ", inX, inY
			
			' Get confirmation
			If (inX > 1) and (inY > 1) Then
				If getConfirm("This will clear the map, are you sure?") Then
					'Delete uMap
					uMap = new gameMap(inX,inY)
				Endif
			Endif
		Endif
		
		If userHotkey( fb.SC_E, fb.SC_CONTROL ) Then
			' Set the selected tile ID
			Dim As Integer ID
			Dim As Integer metaTexture
			
			blackBar()
			Input "TextureID >", ID, metaTexture
			
			If metaTexture Then
				ID += 2048
			Endif
			
			textureID = ID
		Endif
		
		If userHotkey( fb.SC_S, fb.SC_CONTROL ) Then
			' Save the map
			blackBar()
			
			Dim As String fName
			
			Print "File name? (" & fileName & ") > ";
			Input fName
			
			If fName <> "" Then
				fileName = fName
			Endif
			
			LoadingIndicator("Saving...")
			
			Dim As Integer e = uMap->save(fileName)
			If e Then
				LoadingIndicator("Could not save map.")
				errorDialouge(e, __errorTrace)
			Else			
				LoadingIndicator("Saved.")
			Endif
			
			Sleep 1000
		Endif
                
                ' add an object
                If userHotkey( fb.SC_O, fb.SC_CONTROL ) Then
                        Dim As Integer tID = -1
                        
                        blackBar()
                        Input "Object texture (ID) > ", tID
                        
                        If tID <> 0 Then
                                uMap->addObject(editX + 0.5, editY + 0.5,,,tID)
                                
                                blackBar()
                                Print "Added object..."
                                Sleep 1000
                        Endif
                Endif
                
                ' Set player position
                If userHotkey( fb.SC_P, fb.SC_CONTROL ) Then
                        uMap->PlayerX = editX + 0.5
                        uMap->PlayerY = editY + 0.5
                        
                        blackBar()
                        Print "Set player position."
                        Sleep 500
                Endif
                
                If userHotkey( fb.SC_P, fb.SC_LSHIFT ) Then
                        Dim As Double angle
                        
                        blackBar()
                        Input "Player angle> ", angle
                        
                        uMap->playerA = angle * (_pi/180)
                Endif
                
                If userHotkey( fb.SC_F, fb.SC_CONTROL ) Then
                        Dim As Integer r,g,b
                        
                        blackBar()
                        Input "Fog color (r,g,b) > ", r,g,b
                        
                        uMap->fogColor = rgb(r,g,b)
                Endif
                
                If userHotkey( fb.SC_F, fb.SC_LSHIFT ) Then
                        Dim As Integer dist
                        
                        blackBar()
                        Input "Fog Distance > ", dist
                        
                        uMap->fogDistance = dist
                Endif
                
                ' 
                If userHotkey( fb.SC_EQUALS, fb.SC_CONTROL, true ) Then
                        uAtlas->textureSize += 8
                        If uAtlas->textureSize > uAtlas->atlas->width Then
                                uAtlas->textureSize = uAtlas->atlas->width
                        Endif
                Endif
                
                If userHotkey( fb.SC_MINUS, fb.SC_CONTROL, true ) Then
                        uAtlas->textureSize -= 8
                        If uAtlas->textureSize < 8 Then
                                uAtlas->textureSize = 8
                        Endif
                Endif
		
		'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
                ' Map controls
                If userHotkey( fb.SC_EQUALS,, true ) Then
                        mapScale += 1
                        If mapScale > 64 Then
                                mapScale = 64
                        Endif
                Endif
                
                If userHotkey( fb.SC_MINUS,, true ) Then
                        mapScale -= 1
                        If mapScale < 1 Then
                                mapScale = 1
                        Endif
                Endif
                
		' Set the selected texture ID
		If userHotkey( fb.SC_PAGEUP, fb.SC_CONTROL ) Then
			textureID += 10
		Endif
		If userHotkey( fb.SC_PAGEDOWN, fb.SC_CONTROL ) Then
			textureID -= 10
		Endif
		
		If userHotkey( fb.SC_PAGEUP ) Then
			textureID += 1
		Endif
		If userHotkey( fb.SC_PAGEDOWN ) Then
			textureID -= 1
		Endif
		
		' Move around the map
		If userHotkey(fb.SC_W) Then
			editY -= 1
		EndIf
		If userHotkey(fb.SC_S) Then
			editY += 1
		Endif
		If userHotkey(fb.SC_A) Then
			editX -= 1
		EndIf
		If userHotkey(fb.SC_D) Then
			editX += 1
		Endif
		
		If editX < 0 Then
			editX = 0
		ElseIf editX > uMap->mapW Then
			editX = uMap->mapW
		Endif
		
		If editY < 0 Then
			editY = 0
		ElseIf editY > uMap->mapH Then
			editY = uMap->mapH
		Endif
		
		' Edit tiles
		If userHotkey(fb.SC_Q,,false) Then
			uMap->segment(editX, editY).solid = 0
			uMap->segment(editX, editY).textureID = 0
			
			Sleep 1,1
		EndIf
		If userHotkey(fb.SC_E,,false) Then
			uMap->segment(editX, editY).solid = 1
			uMap->segment(editX, editY).textureID = textureID
			
			Sleep 1,1
		Endif
		If userHotkey(fb.SC_F,,false) Then
			uMap->segment(editX, editY).solid = 0
			uMap->segment(editX, editY).textureID = textureID
			
			Sleep 1,1
		Endif
                
                ' Object controls
                If userHotkey(fb.SC_UP,,true) Then
                        selectedObject -= 1
                Endif
                If userHotkey(fb.SC_DOWN,,true) Then
                        selectedObject += 1
                Endif
                
                If selectedObject < 0 Then
                        selectedObject = 0
                Elseif selectedObject > UBound(uMap->mObject) Then
                        selectedObject = UBound(uMap->mObject)
                Endif
		
		' Don't lock up the system lmfao
		Sleep 10,1
		
	Loop Until Multikey(1)
End Sub

Constructor mapEditor()
	
End Constructor

