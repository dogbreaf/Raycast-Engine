' Game egine includes
#include "headers/errors.bi"

#include "headers/imagedata.bi"
#include "headers/textureAtlas.bi"
#include "headers/map.bi"
#include "headers/raycast.bi"

' Defines
#define __XRES 1200
#define __YRES 700

' Editor includes
#include "headers/editor/arguments.bi"
#include "headers/editor/utils.bi"

#include "headers/editor/userinterface.bi"

' Initialisation
ScreenRes __XRES,__YRES,32

Dim As uiContext c = uiContext(10,10,800,600)

Dim As uiListbox t = uiListbox(350,20,256,128)
Dim As uiButton  b = uiButton(110,80,100,15,"Test")

For i As Integer = 0 to 22
        t.add("Item " & i)
Next

c.add( @t )
c.add( @b )

c.add( new uiButton(110,20,100,15,"button") )

c.add( new uiCheckbox(110,40,15,15,"Checkbox") )

c.add( new uiTextInput(110,60,200,15) )

c.add( new uiScrollbar(10,10,15,200) )
c.add( new uiScrollbar(40,210,200,15) )

Dim As String n = dlgFileBrowser("Select")

dlgAlert(n, "OK")

Do
        ScreenLock
        Line (0,0)-(__XRES, __YRES), rgb(0,0,0), BF
        
        c.draw()
        
        ScreenUnlock
        
        c.update()
        
        If b.click Then
                dlgAlert("Alert Box", "Confirm")
        Endif
        
        Sleep 10,1
Loop Until Multikey(1)
