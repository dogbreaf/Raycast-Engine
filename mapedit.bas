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

Dim As uiContext c = uiContext(10,10,512,256)

c.add( new uiButton(110,20,100,15,"button") )

c.add( new uiCheckbox(110,40,15,15,"Checkbox") )

c.add( new uiTextInput(110,60,250,15) )

c.add( new uiScrollbar(10,10,15,200) )
c.add( new uiScrollbar(40,210,200,15) )

Do
        ScreenLock
        Put (c.x, c.y), c.buffer, PSET
        
        ScreenUnlock
        
        c.update()
        Sleep 10,1
Loop Until Multikey(1)
