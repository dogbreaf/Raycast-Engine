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

#include "headers/editor/uitk/ui.bi"
#include "headers/editor/uitk/textinput.bi"
#include "headers/editor/uitk/label.bi"
#include "headers/editor/uitk/window.bi"
#include "headers/editor/uitk/dialouge.bi"

' Initialisation
ScreenRes __XRES,__YRES,32

LoadingIndicator("Loading...")

Sleep
