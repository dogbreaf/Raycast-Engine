#include "headers/errors.bi"
#include "headers/imagedata.bi"
#include "headers/textureatlas.bi"

#include "headers/editor/arguments.bi"

#include "headers/datapack.bi"

Declare Function whoami() As String

Print "Datapack for Raycast-Engine [By Mishka 2020]"
Print

If getOption("-?") or getOption("-h") or command(1) = "" Then
        Print "Usage: "
        Print "  " & command(0) & " <options>"
        Print
        Print "  -p <folder> [-a <author> -t <title>] -o <package>"
        Print "    Pack a folder into a datapack. Author and title are optional. Does not recurse."
        Print "  -e <package> -f <filename> [-o <output filename>]"
        Print "    Extract <filename> from <package>"
        Print "  -i <package>"
        Print "    Show information about a package."
        Print
        Print "  -z <image.bmp> -o <image.img> [--rle]"
        Print "    Convert a bitmap to be stored or back again. If --rle is used, image will be compressed using Run Length Encoding."
        Print "  -x <atlas.dat> -o <image.img|image.bmp>"
        Print "    Extract the texture data from a texture atlas"
        Print
        Print "  Images must be converted to be read directly from a package by the engine."
        Print
        
        End 0
Endif

If getOption("-p") Then
        ' Package a folder
        Dim As datapack package
        Dim As String   directory       = getArgument("-p")
        Dim As String   packName        = getArgument("-o")
        Dim As String   author          = getArgument("-a")
        Dim As String   title           = getArgument("-t")
        
        If directory = "" Then
                Print "Specify a directory!"
                Print
                
                End E_NO_FILE_SPECIFIED
        Endif
        
        If packName = "" Then
                Print "No output specified!"
                Print
                
                End E_NO_FILE_SPECIFIED
        Endif
        
        If author = "" Then
                ' try to get the system username
                author = whoami()
        Endif
        
        If title = "" Then
                title = "Untitled Pack"
        Endif
        
        Print "Create package"
        Print "Author:  " & author
        Print "Title:   " & title
        Print
        Print "Packing files..."; tab(60);
        
        package.header.strTitle = title
        package.header.strAuthor = author
        
        logError(package.packFiles(directory, packname), __errorTrace, true)
        
        Print "DONE"
        Print
        
ElseIf getOption("-e") Then
        ' Extract a file
        Dim As datapack package
        Dim As String   packName          = getArgument("-e")
        Dim As String   fileName          = getArgument("-f")
        Dim As String   outputFile        = getArgument("-o")
        
        If packName = "" Then
                Print "No package specified!"
                Print
                
                End E_NO_FILE_SPECIFIED
        Endif
        
        If fileName = "" Then
                Print "No package specified!"
                Print
                
                End E_NO_FILE_SPECIFIED
        Endif
        
        If outputFile = "" Then
                outputFile = "out." & fileName
        Endif
        
        Print "Reading file indexes..."; tab(60);
        
        logError(package.openPack(packName), __errorTrace, true)
        
        Print "DONE"
        
        Print
        Print "Package details:"
        Print "Author: " & package.header.strAuthor
        Print "Title:  " & package.header.strTitle
        Print
        
        Print "Extracting file..."; tab(60);
        
        logError(package.extractFile(fileName, fileName), __errorTrace, true)
        
        Print "DONE"
        
ElseIf getOption("-i") Then
        ' Show files
        Dim As datapack package
        Dim As String   packName          = getArgument("-i")
        
        If packName = "" Then
                Print "No package specified!"
        Endif
        
        Print "Reading package info..."
        
        logError(package.openPack(packName), __errorTrace, true)
        
        Print
        Print "Author: " & package.header.strAuthor
        Print "Title:  " & package.header.strTitle
        Print
        Print "Files:"
        
        For i As Integer = 0 to UBound(package.file)
                Print "  "; package.file(i).fileName
                Locate csrlin-1,34
                Print (package.file(i).fileSize/1024); "kB"
        Next
        
        Print "    --end of list--"
        Print
        Print "OK."
        Print
        
ElseIf getOption("-z") Then
        ' Convert an image
        Dim As Integer  hndl
        
        Dim As String   inImage = getArgument("-z")
        Dim As String   outImage = getArgument("-o")
        
        Dim As compressionScheme compression = CS_NONE
        
        If inImage = "" Then
                Print "No input specified!"
                Print
                
                End
        Endif
        
        If outImage = "" Then
                Print "No output specified!"
                Print
                
                End
        Endif
        
        Print "Image conversion"
        
        If getOption("--rle") Then
                compression = CS_RLE
                
                Print "using run-length encoding"
        Endif
        
        Print
        
        If Right(inImage,3) = "bmp" and Right(outImage,3) = "img" Then
                Print "Converting bitmap to data image"
                
                ' Convert BMP to IMG
                ScreenRes 120,32,32
                Print "Working..."
                
                ' Create a buffer and read the bitmap image
                Dim As Any Ptr  inputImage
                Dim As Integer  hndl = FreeFile
                Dim As Long  w
                Dim As Long  h
		
		Open inImage For Binary As #hndl 
		
		Get #hndl, 19, w
		Get #hndl, 23, h
		
		Close #hndl
		
		If (w < 1) or (h < 1) Then
                        consolePrint "Could not get image size, is it a bitmap image?"
                        consolePrint ""
                        
			End E_WRONG_FILETYPE
		Endif
                
                inputImage = ImageCreate(w,h,rgb(0,0,0))
                BLoad inImage, inputImage
                
                consolePrint "Input image is " & w & "x" & h
                
                ' Write out the converted image data
                Open outImage For Binary As #hndl
                
                logError(storeImageData(hndl, inputImage, compression), __errorTrace, true)
                
                Close #hndl
                
                ' Reset close the graphics window again
                Screen 0,,, &h80000000
                
                Print "Saved successfully."
                Print
                
                
        ElseIf Right(inImage,3) = "img" and Right(outImage,3) = "bmp" Then
                Print "Converting data image to bitmap"
                
                ' Convert IMG to BMP
                ScreenRes 120,32,32
                Print "Working..."
                
                Dim As fb.Image Ptr  inputImage
                
                ' Open the file
                Dim As Integer  hndl = FreeFile
                
                Open inImage For Binary As hndl
                
                logError(readImageData(hndl, inputImage), __errorTrace, true)
                
                Close #hndl
                
                consolePrint "Input image is " & inputImage->width & "x" & inputImage->height
                
                ' Save the bitmap
                BSave outImage, inputImage
                
                ' Reset close the graphics window again
                Screen 0,,, &h80000000
                
                Print "Saved successfully."
                Print
                
        ElseIf Right(inImage,3) = Right(outImage,3) Then
                Print "Nothing to do, filetypes match."
                Print
                
                End 0
        Else
                Print "One or more unsupported filetypes."
                Print "Please pass one bitmap and one img file as arguments."
                Print
                
                End 0
        Endif
ElseIf getOption("-x") Then
        ' Extract image from texture atlas
        Dim As String atlasFile = getArgument("-x")
        Dim As String outFile = getArgument("-o")
        
        If atlasFile = "" Then
                Print "No texture atlas specified!"
                Print
                
                End E_NO_FILE_SPECIFIED
        Endif
        
        If outFile = "" Then
                Print "No output specified!"
                Print
                
                End E_NO_FILE_SPECIFIED
        Endif
        
        ' Create an image buffer
        ScreenRes 120,32,32
        Print "Working..."
        
        ' Open the atlas
        Dim As textureAtlas     atlas
        
        logError(atlas.loadAtlas(atlasFile), __errorTrace, true)
        
        consolePrint "Image is " & atlas.atlas->width & "x" & atlas.atlas->height
        
        ' Save the image
        If right(outFile, 3) = "bmp" Then
                ' User wants bitmap
                BSave outFile, atlas.atlas
                
        ElseIf right(outFile, 3) = "img" Then
                ' User wants the data image format
                Dim As Integer hndl = FreeFile
                Open outFile For Binary As #hndl
                
                storeImageData(hndl, atlas.atlas, CS_RLE)
                
                Close #hndl
                
        Else
                ' Sorry we don't do anything else
                ConsolePrint "Sorry, only bitmap and data image are supported output formats."
                ConsolePrint ""
                
                End E_BAD_PARAMETERS
        Endif
        
        ' Done
        Screen 0,,, &h80000000
        
        Print "Saved successfully."
        Print
        
Else
        Print "Unknown Option"
        Print
Endif

End 0 

' attempt to get information about the user
Function whoami() As String
        Dim As String ret
        Dim As Integer hndl = FreeFile
        
        ' this appears to work on windows (at least 10), and works on linux
        ' so its good enough for me
        Open Pipe "whoami" For Input As #hndl
        
        Input #hndl, ret
        
        Close #hndl
        
        If ret = "" Then
                ret = "Unkown"
        Endif
        
        Return Trim(ret, Any " " & chr(10) & chr(13))
End Function
