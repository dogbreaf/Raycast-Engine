' Preview the map
'

Function previewMap( ByVal map As gameMap Ptr, ByVal atlas As textureAtlas Ptr, ByVal px As Double, ByVal py As Double ) As errorCode
        Dim As Any Ptr  shade = ImageCreate(__XRES, __YRES, rgba(0,0,0,120))
        Put (0,0), shade, ALPHA
        
        ' Create a raycaster to preview the map
        Dim As raycaster        preview = raycaster(__XRES/3,__YRES/3,1)
        
        preview.map = *map
        
        If preview.atlas.atlas <> 0 Then
                ImageDestroy(preview.atlas.atlas)
                preview.atlas.atlas = 0
        Endif
        preview.atlas.atlas = ImageCreate( atlas->atlas->width, atlas->atlas->height )
        
        Put preview.atlas.atlas, (0,0), atlas->atlas, PSET
        
        preview.atlas.textureSize = atlas->textureSize
        
        If UBound(atlas->mTexture) > -1 Then
                ReDim preview.atlas.mTexture(UBound(atlas->mTexture)) As metaTexture
                
                For i As Integer = 0 to UBound(atlas->mTexture)
                        preview.atlas.mTexture(i) = atlas->mTexture(i)
                Next
        Endif
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        preview.getMapSettings()
        
        preview.playerX = px
        preview.playerY = py
        
        Do
                ScreenLock
                
                Line (32,22)-Step(120,10), rgb(40,40,40), BF
                Draw String (34,24), "Preview (" & CInt(preview.frameRate) & " fps)", rgb(255,255,255)
                
                Put (32,32), preview.screenBuffer, PSET
                
                ScreenUnLock

                logError(preview.draw(), __errorTrace, true)
                logError(preview.update(), __errorTrace, true)
                
                ' Control FOV
                If Multikey(fb.SC_LEFT) Then
                        preview.FOV += 0.5 * (1/preview.frameRate)
                Endif
                If Multikey(fb.SC_RIGHT) Then
                        preview.FOV -= 0.5 * (1/preview.frameRate)
                Endif
                
                ' Control draw distance
                If Multikey(fb.SC_UP) Then
                        preview.drawDistance += 0.5 * (1/preview.frameRate)
                Endif
                If Multikey(fb.SC_DOWN) Then
                        preview.drawDistance -= 0.5 * (1/preview.frameRate)
                Endif
                
        Loop Until userHotKey(fb.SC_ESCAPE,, true)
        
        consolePrint "Close preview"
        
        Return E_NO_ERROR
End Function
