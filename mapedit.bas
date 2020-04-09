' Game egine includes
#include "headers/imagedata.bi"
#include "headers/textureAtlas.bi"
#include "headers/map.bi"
#include "headers/raycast.bi"

' Defines
#define __XRES 1024
#define __YRES 680

' Editor includes
#include "headers/editor/arguments.bi"
#include "headers/editor/utils.bi"

/'
#include "headers/editor/uitk/ui.bi"
#include "headers/editor/uitk/window.bi"
#include "headers/editor/uitk/label.bi"
#include "headers/editor/uitk/textinput.bi"
#include "headers/editor/uitk/dialouge.bi"
'/

#include "headers/editor/atlasEditor.bi"
#include "headers/editor/mapEditor.bi"

' Initialisation
ScreenRes __XRES,__YRES,32

' Variables
Dim As textureAtlas	uAtlas
Dim As gameMap		uMap = gameMap(32,32)

Dim As Integer		selectedTexture
Dim As Integer		editX, editY

Dim As String		fileName

' Editor windows
Dim As mapEditor	thisMapEditor

' Load files specified on the commandline
fileName = getArgument("-m")

If fileName <> "" Then
	uMap.load( fileName )
Else
	uMap = gameMap(32,32)
	fileName = "untitled.dat"
Endif

debugPrint "File: " & fileName

If getArgument("-t") <> "" Then
	debugPrint "Load texture file..."
	
	' Load a texture file
	uAtlas.loadTextures( getArgument("-t") )
	
ElseIf getArgument("-a") <> "" Then
	debugPrint "Load atlas file..."
	
	' Load an atlas
	uAtlas.loadAtlas( getArgument("-a") )
	
Else
	debugPrint "Init empty atlas..."
Endif

''''''''''''''''''''''''''
thisMapEditor.uAtlas = @uAtlas
thisMapEditor.uMap = @uMap
thisMapEditor.fileName = fileName
thisMapEditor.show()

''''''''''''''''''''''''''

