' Game egine includes
#include "headers/errors.bi"

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

#include "headers/editor/previewWindow.bi"

#include "headers/editor/atlasEditor.bi"
#include "headers/editor/mapEditor.bi"

' Initialisation
ScreenRes __XRES,__YRES,32

LoadingIndicator("Loading...")

' Variables
Dim As textureAtlas	uAtlas
Dim As gameMap		uMap = gameMap(32,32)

Dim As Integer		selectedTexture
Dim As Integer		editX, editY

Dim As String		mapFile
Dim As String		atlasFile

' Editor windows
Dim As mapEditor	thisMapEditor

' Load files specified on the commandline
mapFile = getArgument("-m")

If mapFile <> "" Then
	errorDialouge(uMap.loadMap( mapFile ), __errorTrace)
Else
	uMap = gameMap(32,32)
	mapFile = "untitled.dat"
Endif

If getArgument("-t") <> "" Then	
	' Load a texture file
	errorDialouge(uAtlas.loadTextures( getArgument("-t") ), __errorTrace)
	atlasFile = getArgument("-t") & ".dat"
	
ElseIf getArgument("-a") <> "" Then
	' Load an atlas
	errorDialouge(uAtlas.loadAtlas( getArgument("-a") ), __errorTrace)
	atlasFile = getArgument("-a")
	
Else
	debugPrint "Init empty atlas..."
	atlasFile = "untitled.atlas.dat"
	
Endif

''''''''''''''''''''''''''
If getOption("--atlas-editor") Then
	' Just edit the texture atlas
	editAtlas(@uAtlas, atlasFile)
Else
	' Edit the map and texture atlas
	thisMapEditor.uAtlas = @uAtlas
	thisMapEditor.uMap = @uMap
        
	thisMapEditor.fileName = mapFile
	thisMapEditor.atlasFile = atlasFile
	
	thisMapEditor.show()
Endif
''''''''''''''''''''''''''

