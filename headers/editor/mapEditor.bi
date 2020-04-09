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
		
		Line (__XRES - uAtlas->atlas->width - 16 + uAtlas->textureX, 64 + uAtlas->textureY)-Step(32,32), rgb(0,255,0), B
		
		uAtlas->setTexture( uMap->segment(editX, editY).textureID )
		scalePut (, __XRES - uAtlas->atlas->width + 32, 16, 32, 32, uAtlas->texture )
		
		Line (__XRES - uAtlas->atlas->width - 16 + uAtlas->textureX, 64 + uAtlas->textureY)-Step(32,32), rgb(0,255,255), B
		
		' Draw the map top-down
		For y As Integer = 0 to uMap->mapH
			For x As Integer = 0 to uMap->mapW
				If uMap->segment(x,y).solid Then
					uAtlas->setTexture( uMap->segment(x,y).textureID )
					scalePut(, 16+(x*8), 16+(y*8), 8, 8, uAtlas->texture )
				Else
					Line ( 16 + ( x*8 ), 16 + ( y*8 ) )-Step(8,8), rgb(0,0,0), BF
				Endif
			Next
		Next
		
		' Draw the selection box
		Line ( 16 + ( editX*8 ), 16 + ( editY*8 ) )-Step(8,8), rgb(255,0,0), B
		
		ScreenUnlock
		
		' Input polling
		If userHotkey( fb.SC_R, fb.SC_CONTROL ) Then
			' Resize the map
			blackBar()
		
			Dim As Integer inX, inY
			
			Input "Map size (w,h) > ", inX, inY
			
			' Get confirmation
			If getConfirm("This will clear the map, are you sure?") Then
				uMap = new gameMap(inX,inY)
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
			
			uMap->save(fileName)
			
			LoadingIndicator("Saved. (probably)")
			Sleep 1000
		Endif
		
		'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
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
		
		' Don't lock up the system lmfao
		Sleep 1,1
		
	Loop Until Multikey(1)
End Sub

Constructor mapEditor()
	
End Constructor

