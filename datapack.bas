#include "headers/errors.bi"
#include "headers/imagedata.bi"

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
        Print "    Convert a bitmap to be stored. If --rle is used, image will be compressed using Run Length Encoding."
        Print "  -x <image.img> -o <image.bmp>"
        Print "    Convert an image in storage format to a bitmap."
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
        
ElseIf getOption("-x") Then
        ' Convert a bitmap

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
