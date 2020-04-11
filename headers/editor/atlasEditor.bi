Sub editAtlas( ByRef uAtlas As textureAtlas Ptr, ByVal fileName As String = "untitled.atlas.dat" )
	Dim As Integer	listScroll
	Dim As Integer	listSelection
	
	Do
		ScreenLock
		Line (0,0)-(__XRES,__YRES), rgb(30,30,30), BF
		
		' Show the texture atlas
		Put (16,100), uAtlas->atlas, PSET
		
		' Show data about the atlas
		Draw String (16,2), "Texture Atlas Editor"
		
		Draw String (16,88), "Atlas"
		
		Draw String (16,14), "Resoloution:  " & uAtlas->atlas->width & "x" & uAtlas->atlas->height
		Draw String (16,24), "MetaTextures: " & UBound(uAtlas->mTexture)+1
		
		Dim As Integer nTextures = (uAtlas->atlas->width/uAtlas->textureSize)*(uAtlas->atlas->height/uAtlas->textureSize)
		Draw String (200,14), "Number of Textures: " & nTextures
		
		' Preview the selected meta-texture
		Draw String (32+uAtlas->atlas->width,88), "Meta Textures"
		Draw String (48+uAtlas->atlas->width+256,88), "Selected"
		
                ' If this isnt done, the preview texture won't animate
                If UBound(uAtlas->mTexture) > -1 Then
                        If uAtlas->mTexture(listSelection).texType = T_ANIMATED Then
                                uAtlas->setTexture(0)
                        Endif
		Endif
                
		If (UBound(uAtlas->mTexture) >= 0) Then
			uAtlas->setTexture(listSelection + 2048)
			scalePut(,48+uAtlas->atlas->width+256,100,32,32,uAtlas->texture)
			scalePut(,96+uAtlas->atlas->width+256,100,256,256,uAtlas->texture)
		Else
			Line (48+uAtlas->atlas->width+256,100)-Step(32,32), rgb(0,0,0), BF
		Endif
		
		' List the meta-textures
                Dim As String listItems(UBound(uAtlas->mTexture))
                
                For i As Integer = 0 to UBound(uAtlas->mTexture)
                        listItems(i) = i & ": "
                        
                        If uAtlas->mTexture(i+listScroll).texType = T_LARGE Then
                                listItems(i) = listItems(i) & "LRG " & uAtlas->mTexture(i).x & "," & _
                                        uAtlas->mTexture(i).y & " " & _
                                        uAtlas->mTexture(i).w & "x" & _
                                        uAtlas->mTexture(i).h
                        ElseIf uAtlas->mTexture(i+listScroll).texType = T_ANIMATED Then
                                listItems(i) = listItems(i) & "ANI " & uAtlas->mTexture(i).frameStart & "->" & _
                                        uAtlas->mTexture(i).frameEnd
                        Else
                                listItems(i) = "Unknown"
                        Endif
                Next
                selectList( 32 + uAtlas->atlas->width, 100, 256, 400, listItems(), listSelection )                
		ScreenUnlock
		
		' 
		If userHotkey(fb.SC_S, fb.SC_CONTROL) Then
			' Save the atlas
			blackBar()
			
			Dim As String fName
			
			Print "File name? (" & fileName & ") > ";
			Input fName
			
			If fName <> "" Then
				fileName = fName
			Endif
			
			LoadingIndicator("Saving...")
			
			Dim As Integer e = uAtlas->saveAtlas(fileName)
			
			If e Then
				LoadingIndicator("Couldn't save, an error occurred.")
				errorDialouge(e, __errorTrace)
			Else			
				LoadingIndicator("Saved.")
			Endif
			
			Sleep 1000
		Endif
		
		' Scroll the texture list
		If userHotkey(fb.SC_UP) Then
			listSelection -= 1
		Endif
		If userHotkey(fb.SC_DOWN) Then
			listSelection += 1
		Endif
		
		If listSelection < 0 Then
			listSelection = 0
		Elseif listSelection > UBound(uAtlas->mTexture) Then
			listSelection = UBound(uAtlas->mTexture)
		Endif
		
		If userHotkey(fb.SC_A, fb.SC_CONTROL) Then
			' Add a meta-texture
			blackBar()
			
			Dim As textureType	texType
			
			Print "(" & T_LARGE & " = LRG, " & T_ANIMATED & " = ANI) > ";
			Input texType
			
			If texType = T_LARGE Then
				Dim As Integer uX,uY,uW,uH
				
				blackBar()
				Input "Texture Dimensions (x,y,w,h) > ", uX, uY, uW, uH
				
				If (uW > 0) and (uH > 0) Then
					uAtlas->addLargeTexture(uX,uY,uW,uH)
					
					blackBar()
					Print "Added large texture..."
					Sleep 1000
				Endif
			ElseIf texType = T_ANIMATED Then
				Dim As Integer ff,lf,tmp
				
				blackBar()
				Input "Frame Range (first,last) > ", ff, lf
				
				If lf < ff Then
					tmp = ff
					ff = lf
					lf = tmp
				Endif
				
				If lf > 0 Then
					uAtlas->addAnimatedTexture(ff,lf)
					
					blackBar()
					Print "Added animated texture..."
					Sleep 1000
				Endif
			Endif
		Endif
		
		If userHotkey(fb.SC_D, fb.SC_CONTROL) Then
			If getConfirm("Are you sure you want to delete the selected meta-texture? ") Then
				LoadingIndicator("Deleting texture...")
				
				Dim As Integer deleteId = listSelection
				Dim As Integer transferId
				Dim As Integer count = UBound( uAtlas->mTexture )-1
				
				Dim As metaTexture mTexTmp(count)
				
				For i As Integer = 0 to count+1
					If i <> deleteID Then
						mTexTmp(transferId) = uAtlas->mTexture(i)
						transferId += 1
					Endif
				Next
				
				ReDim uAtlas->mTexture(count) As metaTexture
				
				For i As Integer = 0 to count
					uAtlas->mTexture(i) = mTexTmp(i)
				Next
				
				LoadingIndicator("Deleted texture...")
				Sleep 1000
			Endif
		Endif
		
		Sleep 10,1
	Loop Until Multikey(1)
End Sub

