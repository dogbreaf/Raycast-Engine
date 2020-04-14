' A simple UI toolkit
'

' Core utility functions
Enum uiRectType
        RT_ENABLED_BOX
        RT_DISABLED_BOX
        RT_SELECTED_BOX
        RT_ACTIVE_BOX
        RT_FILLED_BOX
End Enum 

Declare Function __inRect( ByVal As Integer, ByVal As Integer, _
                           ByVal As Integer, ByVal As Integer, _
                           ByVal As Integer, ByVal As Integer ) As Boolean
                           
Declare Function __drawRect( ByVal As Any Ptr, _
                             ByVal As Integer, _
                             ByVal As Integer, _
                             ByVal As Integer, _
                             ByVal As Integer, _
                             ByVal As uiRectType ) As Integer

' One element (e.g. button, text input, scrollbar, etc.)
type uiElement Extends Object
        Private:
        
        Public:
        x As Integer
        y As Integer
        
        w As Integer
        h As Integer
        
        Declare Constructor ()
        Declare Constructor ( ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Integer )
        
        Declare Virtual Function update( ByVal As Any Ptr ) As Integer
        Declare Virtual Function draw( ByVal As Any Ptr ) As Integer
end type

' Manage groups of uiElement
type uiContext
        buffer  As fb.Image Ptr
        
        element ( Any ) As uiElement Ptr
        
        x As Integer
        y As Integer
        
        w As Integer
        h As Integer
        
        mouseX As Integer
        mouseY As Integer
        
        mouseBtn1 As Boolean
        mouseBtn2 As Boolean
        mouseBtn3 As Boolean
        
        mouseWheel As Integer
        
        Declare Constructor ( ByVal As Integer, ByVal As Integer, ByVal As Integer, ByVal As Integer )
        
        Declare Function update() As Integer
        Declare Function add( ByVal As Any Ptr ) As Integer
end type

' context initialiser
Constructor uiContext ( ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer )
        this.x = x
        this.y = y
        
        this.w = w
        this.h = h
        
        If this.buffer = 0 Then
                this.buffer = ImageCreate( this.w, this.h, rgb(0,0,0) )
        Endif
End Constructor

' context update function
Function uiContext.update() As Integer
        ' Update the mouse
        Dim As Integer buttons
        Dim As Integer wheel
        
        Static As Integer oldWheel
        
        GetMouse( this.mouseX, this.mouseY, wheel, buttons )
        
        ' correct for the position of the context
        this.mouseX -= x
        this.mouseY -= y
        
        ' Calculate the scrollwheel delta
        this.mouseWheel = wheel-oldWheel
        oldWHeel = wheel
        
        ' check the buttons
        If buttons and 1 Then
                this.mouseBtn1 = true
        Else
                this.mouseBtn1 = false
        Endif
        
        If buttons and 2 Then
                this.mouseBtn2 = true
        Else
                this.mouseBtn2 = false
        Endif
        
        If buttons and 4 Then
                this.mouseBtn3 = true
        Else
                this.mouseBtn3 = false
        Endif
        
        ' Check there is a buffer, and clear it
        If this.buffer = 0 Then
                Return -1
        Endif
        
        Line this.buffer, (0,0)-(this.w, this.h), rgb(20,20,20), BF
        
        Line this.buffer, (0,0)-(this.w-1, this.h-1), rgb(255,255,255), B
        
        ' Update all the UI elements
        If UBound( this.element ) > -1 Then
                For i As Integer = 0 to UBound( this.element )
                        this.element(i)->update(@this)
                        this.element(i)->draw(@this)
                Next
        Endif
End Function

' Add a UI element
Function uiContext.add( ByVal e As Any Ptr ) As Integer
        If e = 0 Then
                Return -1
        Endif
        
        Dim As Integer count = UBound(this.element)+1
        ReDim Preserve this.element(count) as uiElement Ptr
        
        If UBound(this.element) <> count Then
                Return -1
        Endif
        
        this.element(count) = e
        
        Return 0
End Function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Core UI elements
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' A simple button
Type uiButton Extends uiElement
        Private:
        label As String
        
        Public:
        hover As Boolean
        click As Boolean

        Declare Constructor ( ByVal As Integer, ByVal As Integer, _
                              ByVal As Integer, ByVal As Integer, _
                              ByVal As String )
                              
        ' I would add an overloaded constructor that allows passing an
        ' onClick() callback function but without the ability to pass pointers
        ' to member functions this would have limited usabillity.
        '
        ' If that feature is added I will add a callback to allow this behavour
                              
        Declare Function update( ByVal As Any Ptr ) As Integer Override
        Declare Function draw( ByVal As Any Ptr ) As Integer Override
End Type

Constructor uiButton ( ByVal x As Integer, ByVal y As Integer, _
                       ByVal w As Integer, ByVal h As Integer, _
                       ByVal label As String )
                       
        base( x, y, w, h )
        
        this.label = label
End Constructor

Function uiButton.update( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = cast( uiContext Ptr, contextPtr )
        
        If __inRect( context->mouseX, context->mouseY, base.x, _
                     base.y, base.x + base.w, base.y + base.h ) Then
                     
                this.hover = true
                
                If context->mouseBtn1 Then
                        this.click = true
                Else
                        this.click = false
                Endif
        Else
                this.hover = false
                this.click = false
        Endif
        
        Return 0
End Function

Function uiButton.draw( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = cast( uiContext Ptr, contextPtr )
        
        If this.click Then
                __drawRect( context->buffer, this.x, this.y, this.w, this.h, RT_ACTIVE_BOX )
                
        ElseIf this.hover Then
                __drawRect( context->buffer, this.x, this.y, this.w, this.h, RT_SELECTED_BOX )
                
        Else
                __drawRect( context->buffer, this.x, this.y, this.w, this.h, RT_ENABLED_BOX )
                
        Endif
        
        ..Draw String context->buffer, _
                ( this.x + (this.w/2)-(len(this.label)*4), this.y + (this.h/2) - 4 ), _
                this.label, rgb(255,255,255)
        
        Return 0
End Function

' A checkbox
Type uiCheckbox Extends uiElement
        Private:
        label As String
        
        activeTimer As Double
        
        Public:
        hover As Boolean
        click As Boolean
        
        active As Boolean

        Declare Constructor ( ByVal As Integer, ByVal As Integer, _
                              ByVal As Integer, ByVal As Integer, _
                              ByVal As String )
                              
        Declare Function update( ByVal As Any Ptr ) As Integer Override
        Declare Function draw( ByVal As Any Ptr ) As Integer Override
End Type

Constructor uiCheckbox ( ByVal x As Integer, ByVal y As Integer, _
                       ByVal w As Integer, ByVal h As Integer, _
                       ByVal label As String )
                       
        base( x, y, w, h )
        
        this.label = label
End Constructor

Function uiCheckbox.update( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = cast( uiContext Ptr, contextPtr )
        
        If __inRect( context->mouseX, context->mouseY, base.x, _
                     base.y, base.x + base.w, base.y + base.h ) Then
                     
                this.hover = true
                
                If context->mouseBtn1 Then
                        this.click = true
                        
                        If (timer-this.activeTimer)*1000 > 100 Then
                                this.active = not this.active
                                
                                this.activeTimer = timer
                        Endif
                Else
                        this.click = false
                Endif
        Else
                this.hover = false
                this.click = false
        Endif
        
        Return 0
End Function

Function uiCheckbox.draw( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = cast( uiContext Ptr, contextPtr )
        
        If this.active Then
                __drawRect( context->buffer, this.x, this.y, this.w, this.h, RT_FILLED_BOX )
                
        Else
                __drawRect( context->buffer, this.x, this.y, this.w, this.h, RT_ENABLED_BOX )
                
        Endif
        
        ..Draw String context->buffer, _
                ( this.x - (len(this.label)*8) - 8, this.y + (this.h/2) - 4 ), _
                this.label, rgb(255,255,255)
        
        Return 0
End Function

' A text input
Type uiTextInput Extends uiElement
        Private:
        active As Boolean
        
        editPos As Integer
        
        Public:
        hover As Boolean
        click As Boolean
        
        value As String

        Declare Constructor ( ByVal As Integer, ByVal As Integer, _
                              ByVal As Integer, ByVal As Integer )
                              
        Declare Function update( ByVal As Any Ptr ) As Integer Override
        Declare Function draw( ByVal As Any Ptr ) As Integer Override
End Type

Constructor uiTextInput ( ByVal x As Integer, ByVal y As Integer, _
                       ByVal w As Integer, ByVal h As Integer )
                       
        base( x, y, w, h )
End Constructor

Function uiTextInput.update( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = cast( uiContext Ptr, contextPtr )
        
        If __inRect( context->mouseX, context->mouseY, base.x, _
                     base.y, base.x + base.w, base.y + base.h ) Then
                     
                this.hover = true
                
                If context->mouseBtn1 Then
                        this.click = true
                        
                        ' Becomes active when you click in it
                        this.active = true
                        this.editPos = 0
                        
                        Do:Sleep 1,1:Loop Until InKey() = ""
                Else
                        this.click = false
                Endif
        Else
                If context->mouseBtn1 Then
                        ' Looses focus when you click elsewhere
                        this.active = false
                Endif
                
                this.hover = false
                this.click = false
        Endif
        
        ' Process text input
        If this.active Then
                Dim As String k = inKey()
                
                If this.editPos < 0 Then
                        this.editPos = 0
                ElseIf this.editPos > len(this.value) Then
                        this.editPos = len(this.value)
                Endif
                
                If k = chr(8) Then ' Backspace
                        this.value = Left( this.value, len(this.value)-this.editPos-1 ) & Right( this.value, editPos )
                        
                ElseIf ( k = chr(255) & "K" ) Then ' RIGHT
                        this.EditPos += 1
                ElseIf ( k = chr(255) & "M" ) Then ' LEFT
                        this.EditPos -= 1
                ElseIf ( k = chr(255) & "O" ) Then ' END
                        this.EditPos = 0
                ElseIf ( k = chr(255) & "G" ) Then ' HOME
                        this.EditPos = Len( this.value )
                        
                ElseIf ( k = chr(255) & "S" ) Then ' DELETE
                        this.value = Left( this.value, len(this.value)-this.editPos ) & Right( this.value, editPos-1 )
                        this.EditPos -= 1
                        
                ElseIf asc(k) > 31 Then ' Printing characters
                        this.value = Left( this.value, len(this.value)-this.editPos ) & k & Right( this.value, editPos )
                Endif
        Endif
        
        Return 0
End Function

Function uiTextInput.draw( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = cast( uiContext Ptr, contextPtr )
        
        If this.active Then
                __drawRect( context->buffer, this.x, this.y, this.w, this.h, RT_ACTIVE_BOX )
                
        Else
                __drawRect( context->buffer, this.x, this.y, this.w, this.h, RT_ENABLED_BOX )
                
        Endif
        
        Dim As String displayString
        
        If this.active Then
                displayString = Left( this.value, len(this.value)-this.editPos ) & chr(221) & Right( this.value, editPos )
                
                Dim As Integer tmp = len(this.value)-this.editPos
                
                If (this.editPos > (this.w/8)-8) and ( tmp > 0 )  Then
                        If tmp - 4 > 0 Then
                                tmp -= 4
                        Endif

                        displayString = Mid( displayString, tmp, (this.w/8)-1 )
                Else
                        displayString = Right(displayString, (this.w/8)-1)
                Endif
        Else
                displayString = Left(this.value, (this.w/8)-1)
        Endif
        
        ..Draw String context->buffer, _
                ( this.x + (this.w/2)-(len(displayString)*4), this.y + (this.h/2) - 4 ), _
                displayString, rgb(255,255,255)
        
        Return 0
End Function

' A scrollbar
Type uiScrollbar Extends uiElement
        Public:
        hover As Boolean
        click As Boolean
        
        value As Double

        Declare Constructor ( ByVal As Integer, ByVal As Integer, _
                              ByVal As Integer, ByVal As Integer )
                              
        Declare Function update( ByVal As Any Ptr ) As Integer Override
        Declare Function draw( ByVal As Any Ptr ) As Integer Override
End Type

Constructor uiScrollbar ( ByVal x As Integer, ByVal y As Integer, _
                       ByVal w As Integer, ByVal h As Integer )
                       
        base( x, y, w, h )
End Constructor

Function uiScrollbar.update( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = cast( uiContext Ptr, contextPtr )
        
        If __inRect( context->mouseX, context->mouseY, base.x, _
                     base.y, base.x + base.w, base.y + base.h ) Then
                     
                this.hover = true
                
                If context->mouseBtn1 Then
                        this.click = true
                Else
                        this.click = false
                Endif
        Else
                this.hover = false
                this.click = false
        Endif
        
        If this.click Then
                ' Update the position
                If this.w > this.h Then
                        ' Horizontal mode
                        If context->mouseX - this.x < this.w Then
                                this.value = ( context->mouseX - this.x )/this.w
                        Endif
                        
                Else
                        ' Vertical Mode
                        If context->mouseY - this.y < this.h Then
                                this.value = ( context->mouseY - this.y )/this.h
                        Endif
                        
                Endif
        Endif
        
        Return 0
End Function

Function uiScrollbar.draw( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = cast( uiContext Ptr, contextPtr )
        
        If this.w > this.h Then
                ' Draw horizontally
                __drawRect( context->buffer, this.x, this.y, this.w+this.h, this.h, RT_DISABLED_BOX )
                __drawRect( context->buffer, this.x + (this.value*this.w), this.y, this.h, this.h, RT_ENABLED_BOX )
        Else
                ' Draw vertically
                __drawRect( context->buffer, this.x, this.y, this.w, this.h+this.w, RT_DISABLED_BOX )
                __drawRect( context->buffer, this.x, this.y + (this.value*this.h), this.w, this.w, RT_ENABLED_BOX )
        Endif
        
        Return 0
End Function

' List box
Type uiListbox Extends uiElement
        Private:
        list (Any)      As String
        
        scrollbar       As uiScrollbar Ptr
        
        Public:
        selectedID      As Integer
        
        Declare Constructor ( ByVal As Integer, ByVal As Integer, _
                              ByVal As Integer, ByVal As Integer )
                              
        Declare Function update( ByVal As Any Ptr ) As Integer Override
        Declare Function draw( ByVal As Any Ptr ) As Integer Override
        
        Declare Function add( ByVal As String ) As Integer
        Declare Function clear() As Integer
End Type

Constructor uiListbox ( ByVal x As Integer, ByVal y As Integer, _
                        ByVal w As Integer, ByVal h As Integer )
                       
        base( x, y, w, h )
        
        scrollbar = new uiScrollbar( x + w + 10, y, 15, h - 15 )
End Constructor

Function uiListbox.update( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = Cast( uiContext Ptr, contextPtr )
        
        scrollbar->update(contextPtr)
        
        If __inRect( context->mouseX, context->mouseY, base.x, _
                     base.y, base.x + base.w, base.y + base.h ) Then

                If context->mouseBtn1 Then
                        Dim As Integer listLen = UBound( this.list )
                        Dim As Integer listScr = listLen * scrollbar->value
                        Dim As Integer dispLen = (this.h/10)-2
                        Dim As Integer sx = context->mouseY-this.y
                        
                        this.selectedID = ( dispLen*(sx/this.h) ) + listScr
                Endif
        Endif
        
        this.selectedID -= context->mouseWheel
        
        If this.selectedID > UBound( this.list ) Then
                this.selectedID = UBound( this.list )
        ElseIf this.selectedID < 0 Then
                this.selectedID = 0
        Endif
        
        Return 0
End Function

Function uiListbox.draw( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr context = Cast( uiContext Ptr, contextPtr )
        
        __drawRect( context->buffer, this.x, this.y, this.w, this.h, RT_ENABLED_BOX )
        
        scrollbar->draw(contextPtr)
        
        ''''''''''''''''''
        Dim As Integer listLen = UBound( this.list )
        Dim As Integer dispLen = (this.h/10)-2
        Dim As Integer listScr = listLen * scrollbar->value
        
        For i As Integer = 0 to dispLen
                
                Dim As UInteger fg = rgb(255,255,255)
                Dim As UInteger bg = rgb(0,0,0)
                
                If i+listScr = this.selectedID Then
                        fg = rgb(0,0,0)
                        bg = rgb(255,255,255)
                Endif
                
                Dim As Integer xp = this.x + 2
                Dim As Integer yp = this.y + 2 + ( i * 10 )
                
                If i+listScr < listLen Then
                        Line context->buffer, (xp, yp)-step(this.w-3,9), bg, BF
                        ..Draw String context->buffer, ( xp , yp ), _
                                this.list(i+listScr), fg
                Endif
                
        Next
        
        Return 0
End Function

Function uiListbox.add( ByVal item As String ) As Integer
        Dim As Integer count = UBound( this.list )+1
        
        ReDim Preserve this.list(count) As String
        
        If UBound(this.list) <> count Then
                Return -1
        Endif
        
        this.list(count) = item
        
        Return count
End Function

Function uiListbox.clear() As Integer
        ReDim this.list(-1) As String
        
        If UBound(this.list) <> -1 Then
                Return -1
        Endif
        
        Return 0
End Function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Override these functions in custom UI elements
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

' Default constructor for uiElement
Constructor uiElement ( ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, ByVal h As Integer )
        this.x = x
        this.y = y
        
        this.w = w
        this.h = h
End Constructor

' Default update function for uiElement
Virtual Function uiElement.update( ByVal contextPtr As Any Ptr ) As Integer
        Return 0
End Function

' Default draw function for uiElement
Virtual Function  uiElement.draw( ByVal contextPtr As Any Ptr ) As Integer
        Dim As uiContext Ptr    context = Cast( uiContext Ptr, contextPtr )
        
        If ( context = 0 ) or ( context->buffer = 0 ) Then
                Return -1
        Endif
        
        Line context->buffer, (this.x, this.y)-step(this.w, this.h), rgb(255,255,255), BF
        
        Return 0
End Function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Core utility functions
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Function __inRect( ByVal tX As Integer, ByVal tY As Integer, _
                   ByVal x1 As Integer, ByVal y1 As Integer, _
                   ByVal x2 As Integer, ByVal y2 As Integer ) As Boolean

        If ( tX > x1 ) and ( tX < x2 ) and ( tY > y1 ) and ( tY < y2 ) Then
                Return true
        Else
                Return false
        Endif
End Function

Function __drawRect( ByVal dest As Any Ptr, _
                     ByVal x As Integer, _
                     ByVal y As Integer, _
                     ByVal w As Integer, _
                     ByVal h As Integer, _
                     ByVal m As uiRectType ) As Integer
        
        Select Case m
        
        Case RT_ENABLED_BOX
                Line dest, (x,y)-step(w,h), rgb(0,0,0),         BF
                Line dest, (x,y)-step(w,h), rgb(255,255,255),   B
                
        Case RT_DISABLED_BOX
                Line dest, (x,y)-step(w,h), rgb(80,80,80),      BF
                Line dest, (x,y)-step(w,h), rgb(255,255,255),   B
                
        Case RT_SELECTED_BOX
                Line dest, (x,y)-step(w,h), rgb(0,0,0),         BF
                Line dest, (x,y)-step(w,h), rgb(255,255,255),   B
                
                Line dest, ( x + 3, y + 3 )-step( w - 6, h - 6 ), _
                        rgb(255,255,255), B, &b1010101010101010

        Case RT_ACTIVE_BOX
                Line dest, (x,y)-step(w,h), rgb(0,0,0),         BF
                Line dest, (x,y)-step(w,h), rgb(255,255,255),   B
                
                Line dest, ( x + 3, y + 3 )-step( w - 6, h - 6 ), _
                        rgb(255,255,255), B, &b1010101010101010
                        
                Line dest, (x+1,y+1)-step(w,h), rgb(255,255,255),   B
                
        Case RT_FILLED_BOX
                Line dest, (x,y)-step(w,h), rgb(0,0,0),         BF
                Line dest, (x,y)-step(w,h), rgb(255,255,255),   B
                
                Line dest, ( x + 3, y + 3 )-step( w - 6, h - 6 ), _
                        rgb(255,255,255), BF
                
                
        Case Else
                Line dest, (x,y)-STEP(w,h), rgb(255,0,255), B, &b1010101010101010
                Return -1
                
        End Select
        
        Return 0
End Function
