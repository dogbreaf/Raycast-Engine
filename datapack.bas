#include "headers/errors.bi"
#include "headers/imagedata.bi"

#include "headers/editor/arguments.bi"

#include "headers/datapack.bi"

Dim As datapack test
Dim As datapack test2

test.header.strAuthor = "Mishka"
test.header.strTitle = "test"

Screenres 640,480,32

logError(test2.packFiles("foo", "test.arc"), __errorTrace, true)

Print
Print

logError(test.openPack("test.arc"), __errorTrace, true)

logError(test.extractFile("texture.bmp", "test.dat"), __errorTrace, false)
logError(test.extractFile("atlas.dat", "test.dat"), __errorTrace, false)

Print "OK"
Sleep
