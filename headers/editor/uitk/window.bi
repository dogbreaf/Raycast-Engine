''
''	Flexable window
''

type uiWindow
	context		As uiContext		' context for UI elements
	element(any)	As uiElement Ptr	' embedded elements
	
	titlebar	As UiButton		' the titlebar
	
	' settings flags
	optTitlebar	As Boolean
	optMoveable	As Boolean
	
	' subroutines
	declare sub set( ByVal As Integer, _
			 ByVal As Integer, _
			 ByVal As Integer = -1, _
			 ByVal As Integer = -1, _
			 ByVal As String = "Untitled Window", _
			 ByVal As Boolean = true, _
			 ByVal As Boolean = true _
			)
	
	declare sub add ( ByVal As uiElement Ptr, ByVal As Boolean = true )
	declare sub put ()
	declare sub update ()
end type

sub uiWindow.set( ByVal x As Integer, _
		  ByVal y As Integer, _
		  ByVal w As Integer = -1, _
		  ByVal h As Integer = -1, _
		  ByVal title As String = "Untitled Window", _
		  ByVal optTitlebar As Boolean = true, _
		  ByVal optMoveable As Boolean = true _
		)

	' window setup
	this.context.set(x,y,w,h)
	
	' titlebar setup
	this.titlebar.set(0,0,w,20, title, rgb(250,200,200))
	this.titlebar.setContext(@this.context)
	
	this.optTitlebar = optTitlebar
	this.optMoveable = optMoveable
end sub

sub uiWindow.add( ByVal element As uiElement Ptr, ByVal selfContext As Boolean = true )
	Dim numElements As Integer = UBound(this.element)
	
	' Expand the array
	Redim preserve this.element(numElements+1)
	
	' Add this object's pointer to the list of pointers
	this.element(numElements+1) = element
	
	if selfContext then
		element->setContext(@this.context)
	endif
end sub

sub uiWindow.put()
	ScreenLock
	     
	if this.optTitlebar then
		this.titlebar.put()
	endif

	' Draw embedded elemets to the context
	if not (LBound(this.element) > UBound(this.element)) then
		for i As Integer = 0 to UBound(this.element)
			this.element(i)->put()
		next
	endif
	
	' draw the context
	this.context.put()
	
	' Window decorations
	line ( this.context.posX, this.context.posY)-STEP _
	     ( this.context.buffer->width, this.context.buffer->height ), _
	     rgb(20,20,20), B
	
	ScreenUnlock
end sub

sub uiWindow.update()
	' update the context
	this.context.update()
	
	' If the cursor isnt in the window don't do anything	
	If this.context.active Then	
		if optTitlebar then
			this.titlebar.update()
		endif
		
		' Update all embedded element logic
		if not (LBound(this.element) > UBound(this.element)) then
			for i As Integer = 0 to UBound(this.element)
				this.element(i)->update()
			next
		endif
		
		' Window movement etc
		if optMoveable andalso this.titlebar.onClick() then
			this.context.set( this.context.mouseX + this.context.posX - (this.context.buffer->width/2), _
					  this.context.mouseY + this.context.posY - 10 )
		
			this.context.refresh = true
		endif
	Endif
end sub

