''
''	Various dialouge boxes
''	By Mishka
''

#define uiDefaultShade 1

'' Decoratively shade the screen to move focus
sub uiShadeScreen( ByVal style As Integer = 0)
	Dim As Integer		xres, yres
	Dim As uiColor		pixel
	Dim As uiColor		shade
	
	shade.value = rgb(20,20,20)
	
	ScreenInfo xres,yres
	
	Select Case style
	
	Case 0
		for y as integer = 0 to yres step 2
			for x as integer = 0 to xres step 2
				pset (x,y), shade.value
				pset (x+1,y+1), shade.value
			next
		next
		
	Case 1
		for y as integer = 0 to yres
			for x as integer = 0 to xres
				pixel.value = point(x,y)
				pixel.avg(shade)
				
				pset (x,y), pixel.value
			next
		next
	
	Case else
		Line (0,0)-(xres,yres), shade.value, BF
	end select
end sub

'' Two button yes or no
function uiDlgConfirm( ByVal query As String, _
		       ByVal btnCancelTxt As String = "Cancel", _
		       ByVal btnConfirmTxt As String = "OK", _
		       ByVal icon As Any Ptr = 0 ) As Integer

	' variables we need
	Dim As uiBox		box
	Dim As uiContext	context
	Dim As uiLabel		message
	Dim As uiButton		confirm
	Dim As uiButton		cancel
	
	Dim As Integer		xres, yres
	Dim As Integer		dlgw, dlgh
	
	' get the screen resoloution to work out where to position the dialouge
	ScreenInfo xres,yres
	
	dlgw = xres/2
	dlgh = 100
	
	' initialise the UI
	context.set( (xres/2)-(dlgw/2), (yres/2)-(dlgh/2), dlgw, dlgh )
	
	box.position.set( (xres/2)-(dlgw/2)-2, (yres/2)-(dlgh/2)-2, dlgw+2, dlgh+2 ) 
	box.color.value = uidefaultColor
	box.style = convex_embossed
	
	message.set( 10, 10, dlgw-20, 20, query )
	message.setContext(@context)
	
	confirm.set( dlgw-120, dlgh-30, 100, 20, btnConfirmTxt, rgb( 130, 160, 140 ) ) 
	confirm.setContext(@context)
	
	cancel.set( dlgw-240, dlgh-30, 100, 20, btnCancelTxt, rgb( 160, 140, 140 ) )
	cancel.setContext(@context) 
	
	' Shade the screen
	uiShadeScreen(uiDefaultShade)
	
	' Enter the main loop
	Do Until Multikey(1)
		' Update objects
		context.update()
		
		confirm.update()
		cancel.update()
		
		' Logic
		if confirm.onClick() then
			return 1
		elseif cancel.onClick() then
			return 0
		endif
		
		' Draw objects
		ScreenLock
		box.put()
		
		message.put()
		confirm.put()
		cancel.put()
		
		context.put()
		ScreenUnLock
		
		sleep 1,1
	Loop
	
	return -1

end function

'' one button confirm
function uiDlgAlert( ByVal query As String, _
		       ByVal btnConfirmTxt As String = "OK", _
		       ByVal icon As Any Ptr = 0 ) As Integer

	' variables we need
	Dim As uiBox		box
	Dim As uiContext	context
	Dim As uiLabel		message
	Dim As uiButton		confirm
	
	Dim As Integer		xres, yres
	Dim As Integer		dlgw, dlgh
	
	' get the screen resoloution to work out where to position the dialouge
	ScreenInfo xres,yres
	
	dlgw = xres/2
	dlgh = 100
	
	' initialise the UI
	context.set( (xres/2)-(dlgw/2), (yres/2)-(dlgh/2), dlgw, dlgh )
	
	box.position.set( (xres/2)-(dlgw/2)-2, (yres/2)-(dlgh/2)-2, dlgw+2, dlgh+2 ) 
	box.color.value = uidefaultColor
	box.style = convex_embossed
	
	message.set( 10, 10, dlgw-20, 20, query )
	message.setContext(@context)
	
	confirm.set( dlgw-120, dlgh-30, 100, 20, btnConfirmTxt, rgb( 130, 160, 140 ) ) 
	confirm.setContext(@context)
	
	' Shade the screen
	uiShadeScreen(uiDefaultShade)
	
	' Enter the main loop
	Do Until Multikey(1)
		' Update objects
		context.update()
		
		confirm.update()
		
		' Logic
		if confirm.onClick() then
			return 1
		endif
		
		' Draw objects
		ScreenLock
		box.put()
		
		message.put()
		confirm.put()
		
		context.put()
		ScreenUnLock
		
		sleep 1,1
	Loop
	
	return -1

end function

'' Text input
function uiDlgInput( ByVal query As String, _
		       ByVal btnCancelTxt As String = "Cancel", _
		       ByVal btnConfirmTxt As String = "OK", _
		       ByVal txtInputTxt As String = "", _
		       ByVal icon As Any Ptr = 0 ) As String

	' variables we need
	Dim As uiBox		box
	Dim As uiContext	context
	Dim As uiLabel		message
	Dim As uiTextInput	txtInput
	
	Dim As uiButton		confirm
	Dim As uiButton		cancel
	
	Dim As Integer		xres, yres
	Dim As Integer		dlgw, dlgh
	
	' get the screen resoloution to work out where to position the dialouge
	ScreenInfo xres,yres
	
	dlgw = xres/2
	dlgh = 150
	
	' initialise the UI
	context.set( (xres/2)-(dlgw/2), (yres/2)-(dlgh/2), dlgw, dlgh )
	
	box.position.set( (xres/2)-(dlgw/2)-2, (yres/2)-(dlgh/2)-2, dlgw+2, dlgh+2 ) 
	box.color.value = uidefaultColor
	box.style = convex_embossed
	
	message.set( 10, 10, dlgw-20, 20, query )
	message.setContext(@context)
	
	txtInput.set (10,40, dlgw-20, 20)
	txtInput.setContext(@context)
	txtInput.value = txtInputTxt
	txtInput.box.text = txtInputTxt
	
	confirm.set( dlgw-120, dlgh-30, 100, 20, btnConfirmTxt, rgb( 130, 160, 140 ) ) 
	confirm.setContext(@context)
	
	cancel.set( dlgw-240, dlgh-30, 100, 20, btnCancelTxt, rgb( 160, 140, 140 ) )
	cancel.setContext(@context) 
	
	' Shade the screen
	uiShadeScreen(uiDefaultShade)
	
	' Enter the main loop
	Do Until Multikey(1)
		' Update objects
		context.update()
		
		confirm.update()
		cancel.update()
		
		txtInput.update()
		
		' Logic
		if confirm.onClick() then
			Exit Do
		elseif cancel.onClick() then
			return ""
		endif
		
		' Draw objects
		ScreenLock
		box.put()
		
		message.put()
		txtInput.put()
		confirm.put()
		cancel.put()
		
		context.put()
		ScreenUnLock
		
		sleep 1,1
	Loop
	
	return txtInput.value

end function

