''
'' Super basic UI toolkit for building simple tools based on the fbgfx library 
'' By Mishka 
''
#include "fbgfx.bi"

#define uiDefaultColor rgb(130,140,140)

' declare the glue logic that is at the bottom
declare function inBounds( ByVal x As Integer, _
			   ByVal y As Integer, _
			   ByVal boundX As Integer, _
			   ByVal boundY As Integer, _
			   ByVal boundW As Integer, _
			   ByVal boundH As Integer _
			  ) as boolean

' Potential styles of box that can be drawn
enum uiBoxStyle
	blank
	convex_embossed
	concave_embossed
end enum

' Easier way to store the position and size of elements
type uiCoords
	x As Integer
	y As Integer

	width As Integer
	height As Integer

	declare sub set( ByVal As Integer, _
			 ByVal As Integer, _
			 ByVal As Integer = -1, _
			 Byval As Integer = -1)
end type

' quickly set all values
sub uiCoords.set( ByVal a As Integer, _
		  ByVal b As Integer, _
		  ByVal c As Integer = -1, _
		  Byval d As Integer = -1)
	this.x = a
	this.y = b

	' Only set the width and height if the values were explicitly specified
	if ( c > -1 ) andalso ( d > -1 ) then
		this.width = c
		this.height = d
	endif
end sub

' Object represents a colour by it's components as well as an unsigned 32bit integer
' which is compatable with the graphics library
union uiColor
	value As uInteger
	type
		r As uByte
		g As uByte
		b As uByte
		a As uByte
	end type

	''TODO: Add overloads where you can pass a stright rgb value or that return a
	''      32bit uint instead of modifying the color
	declare sub add( ByRef As uiColor ) 
	declare sub mul( ByRef As uiColor ) 
	declare sub avg( ByRef As uiColor ) 
end union

' Add the colour values of two colours (uses byref to save memory and be faster) 
sub uiColor.add( ByRef that As uiColor ) 
	this.r += that.r
	this.g += that.g
	this.b += that.b
	this.a += that.a
end sub

' Multiply two colour values
sub uiColor.mul( ByRef that As uiColor ) 
	this.r *= that.r
	this.g *= that.g
	this.b *= that.b
	this.a *= that.a
end sub

' average two colour values
sub uiColor.avg( ByRef that As uiColor ) 
	this.r = ( this.r + that.r ) / 2
	this.g = ( this.g + that.g ) / 2
	this.b = ( this.b + that.b ) / 2
	this.a = ( this.a + that.a ) / 2
end sub

' Object represents the visual component of a ui element 
type uiBox
	style		As uiBoxStyle	= convex_embossed
	active		As Boolean

	position	As uiCoords
	color		As uiColor

	text		As String
	
	' runs the callback in the draw thread for custom graphics
	drawCallback	As Sub ( ByVal As uiBox Ptr, ByVal As Any Ptr ) = 0 
	
	declare sub put ( ByVal As Any Ptr = 0 )
end type

' Draw the box on the screen
sub uiBox.put ( ByVal tgt As Any Ptr = 0 )
	' Define the shade values
	Dim dark As uiColor : dark.value = rgb(20,20,20)
	Dim ligt As uiColor : ligt.value = rgb(200,200,200)
	
	' Mix the element color
	dark.avg(this.color)
	ligt.avg(this.color)
		
	' All box styles are filled with the base colour
	Line tgt, ( this.position.x, this.position.y )- _ 
		  STEP( this.position.width, this.position.height ), _
		  this.color.value, _
		  BF
		  
	Select Case this.style
	Case blank
		' We already drew a box nothing else needs done
		
	Case convex_embossed
		' Looks like it is coming out of the screen
		' top left is light, bottom right is dark 
		Line tgt, ( this.position.x, this.position.y )- _
			  STEP(this.position.width, this.position.height), _
			  dark.value, _
			  B
			  
		Line tgt, ( this.position.x, this.position.y )- _ 
			  STEP(this.position.width, 0), _
			  ligt.value
		Line tgt, ( this.position.x, this.position.y )- _ 
			  STEP( 0, this.position.height ), _
			  ligt.value
	
	Case concave_embossed
		' the opposite of convex		
		' top left is light, bottom right is dark 
		Line tgt, ( this.position.x, this.position.y )- _
			  STEP(this.position.width, this.position.height), _
			  ligt.value, _
			  B
			  
		Line tgt, ( this.position.x, this.position.y )- _ 
			  STEP(this.position.width, 0), _
			  dark.value
		Line tgt, ( this.position.x, this.position.y )- _ 
			  STEP( 0, this.position.height ), _
			  dark.value

	End Select
	
	' If the element is active indicate with a dotted box
	if this.active then
		Line tgt, ( this.position.x + 2, this.position.y + 2 )- _
			  STEP( this.position.width - 4, this.position.height - 4), _
			  dark.value, _
			  B, _
			  &b1010101010101010
	endif
	
	' Draw the contained text in the center of the button
	Dim As String textToDraw = this.text
	
	' make sure that the text isnt too long for the box
	if ( 8*len(textToDraw) > this.position.width ) then
		textToDraw = right(textToDraw, (this.position.width/8))
	endif
	
	' Calculate the length of the string in pixels
	Dim As Integer textWidth = 8*len(textToDraw)
	
	Draw String tgt, ( this.position.x + ( this.position.width/2 ) - ( textWidth/2 ), _
		           this.position.y + ( this.position.height/2 ) - 3 ), _
		    textToDraw, _
		    rgb(0,0,0)
	
	' Draw the draw callback 
	if drawCallback <> 0 then
		drawCallback( @this, tgt )
	endif
end sub

''
'' Functional Code
''

' Context allows elements to share code and potentially be aware of eachoter
' mostly I needed a way to not have every UI element individually poll the mouse
' and it grew arms and legs
type uiContext
	' The context tracks mouse movement
	mouseX		As Integer
	mouseY		As Integer
	mouseZ		As Integer
	
	mouseBtn1	As Boolean
	mouseBtn2	As Boolean
	mouseBtn3	As Boolean
	
	' Stores keyboard input from inkey()
	keybuffer	As String
	
	' The graphics buffer that elements draw to
	buffer		As fb.Image Ptr
	posX		As Integer
	posY		As Integer
	
	' background color
	color		As uiColor
	
	' Causes everything to refresh
	refresh		As Boolean
	redraw		As Boolean = true
	
	' Wether the mouse is in the context area
	active		As Boolean
	
	' Set the location and background of the context
	declare sub set( ByVal x As Integer, _
			 ByVal y As Integer, _
			 ByVal w As Integer = -1, _
			 ByVal h As Integer = -1, _
			 ByVal c As UInteger = uiDefaultColor _
			)
			
	' Visual and logic update routines
	declare sub put()
	declare sub update()
end type

' Set the context properties
sub uiContext.set( ByVal x As Integer, _
		   ByVal y As Integer, _
		   ByVal w As Integer, _
		   ByVal h As Integer, _
		   ByVal c As UInteger = uiDefaultColor _
		)
		
	if w = -1 or h = -1 then
		this.posX = x
		this.posY = y
		
		return
	endif
		
	if this.buffer <> 0 then
		imagedestroy(this.buffer)
	endif
		
	this.buffer = ImageCreate(w,h)
	this.posX = x
	this.posY = y
	
	this.color.value = c
end sub

' draw the buffer
sub uiContext.put()	
	' Draw the buffer to the screen
	..put (this.posX, this.posY), buffer, ALPHA
	
	' reset the refresh flag
	if this.refresh then
		this.refresh = 0
	endif
	
	' fill the buffer with the background color when it needs refreshed 
	if this.redraw then
		Line this.buffer, _
			(0,0)- _
			(this.buffer->width, this.buffer->height), _
			this.color.value, BF
		this.redraw = false
		this.refresh = true
	endif
end sub

' Update the context (poll hardware etc.)
sub uiContext.update()
	Dim buttonMask As Integer	' get mouse does not return discreet values
	
	' Update the mouse position
	getMouse( this.mouseX, this.mouseY, this.mouseZ, buttonMask )
	
	' Don't update any more unless the mouse is on the context area
	' to prevent multiple context's polling InKey() and making trouble
	If inBounds(this.mouseX, this.mouseY, this.posX, this.posY, this.buffer->width, this.buffer->height) Then
		this.active = true
		
		' Subtract the buffer position from the mouse location
		this.mouseX = this.mouseX - this.posX
		this.mouseY = this.mouseY - this.posY
		
		' Extract the mouse button values
		mouseBtn1 = buttonMask and 1
		mouseBtn2 = buttonMask and 2
		mouseBtn3 = buttonMask and 4
		
		' Grab keyboard data from inKey()
		keybuffer = inkey()
	Else
		this.mouseX = 0
		this.mouseY = 0
		this.mouseZ = 0
		
		this.mouseBtn1 = 0
		this.mouseBtn2 = 0
		this.mouseBtn3 = 0
		
		this.active = false
	Endif
end sub

''
'' Base for all UI elements to save on duplicate code
''
type uiElement extends object
	box	As uiBox
	
	context	As uiContext Ptr	' points to the context
	refresh	As Boolean		' Redraw this element
					' will also redraw with the context
	
	value	As String		' Used differently by different elements
	active	As Boolean		' same
	
	' Set the context 
	declare sub setContext( ByVal As uiContext Ptr )
	
	' set the visual properties
	declare sub set( ByVal x As Integer, _
			 ByVal y As Integer, _
			 ByVal w As Integer = -1, _
			 ByVal h As Integer = -1, _
			 ByVal t As String = "", _
			 ByVal c As UInteger = uiDefaultColor _
			)
	
	' draw the element to the context
	declare sub put()
	
	' update element logic
	declare virtual sub update()
	
	' Functions that are the same between all elements
	declare function mouseOn() As Boolean
	declare function onClick() As Boolean
end type

sub uiElement.setContext( ByVal context As uicontext Ptr )
	this.context = context
end sub

sub uiElement.set( ByVal x As Integer, _
		   ByVal y As Integer, _
		   ByVal w As Integer = -1, _
		   ByVal h As Integer = -1, _
		   ByVal t As String = "", _
		   ByVal c As UInteger = uiDefaultColor _
		)

	this.box.position.set(x,y,w,h)
	this.box.color.value = c
	this.box.text = t
end sub

sub uiElement.put()
	if ( this.refresh ) or ( this.context->refresh ) then
		this.box.put( context->buffer )
		
		this.refresh = false
	endif
end sub

virtual sub uiElement.update()
	'' Does nothing by default
end sub

function uiElement.mouseOn() As Boolean
	if inBounds( this.context->mouseX, _
		     this.context->mouseY, _
		     this.box.position.x, _
		     this.box.position.y, _
		     this.box.position.width, _
		     this.box.position.height _
		   ) then
		return true   
	endif
	
	return false
end function

function uiElement.onClick() As Boolean
	if this.mouseOn() andalso context->mouseBtn1 then
		return true
	endif
	
	return false
end function

''
'' Button object
''

type uiButton extends uiElement
	declare constructor ()
	declare sub update()
end type

constructor uiButton()
	this.box.style = convex_embossed
	this.refresh = true
end constructor

sub uiButton.update()
	if this.mouseOn() then
		' Show the active box when hovered over
		this.box.style = convex_embossed
		this.box.active = true
		this.refresh = true
		
		if this.onClick then
			' invert when clicked on
			this.box.style = concave_embossed
			this.refresh = true
		endif
		
	elseif this.box.active then
		' if the button state is active but the mouse isnt over it
		' then reset everything
		this.box.active = false
		this.box.style = convex_embossed
		this.refresh = true
	endif
end sub

''
'' Glue logic
''
function inBounds( ByVal x As Integer, _
		   ByVal y As Integer, _
		   ByVal boundX As Integer, _
		   ByVal boundY As Integer, _
		   ByVal boundW As Integer, _
		   ByVal boundH As Integer _
		  ) as boolean
	
	if ( x > boundX ) andalso ( x < boundX+boundW ) _
	   andalso ( y > boundY ) andalso ( y < boundY+boundH ) then
	   
		return true
	endif
	
	return false
end function

