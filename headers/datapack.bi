' Combine map, image and texture atlas files into one file
'
#include once "file.bi"

' Stores information about the datapack
type datapackHeader
        ' So we can check that we are actually reading a data pack
        identifier      As ULongInt = &h0140
        
        ' Information about the datapack and who made it
        strTitle        As String*32
        strAuthor       As String*32
        
        ' The offset of the first record
        firstOffset     As UInteger
        
        ' How much spacing to give the files
        fileSpacing     As UInteger = 512
end type

' Stores records for one file
type datapackFile
        ' The name of the file
        fileName        As String*32
        
        ' The length of the file
        fileSize        As ULongInt
        
        ' The location of the next record
        nextFile        As ULongInt
end type

' OOP type for managing files
type datapack
        header          As datapackHeader
        file(Any)       As datapackFile
        
        fileHandle      As Integer
        
        ' The current file record
        currentFile     As datapackFile Ptr
        
        Declare Function seekToFile( ByVal As String ) As errorCode
        Declare Function extractFile( ByVal As String, ByVal As String ) As errorCode
        
        Declare Function packFiles( ByVal As String, ByVal As String ) As errorCode
        Declare Function openPack( ByVal As String ) As errorCode
        Declare Function closePack() As errorCode
end type

Function datapack.seekToFile( ByVal fname As String ) As errorCode
        ' Make sure there is something to look for
        If fname = "" Then
                Return E_NO_FILE_SPECIFIED
        Endif
        
        ' Make sure there is an open file to read from
        If this.fileHandle = 0 Then
                Return E_BAD_PARAMETERS
        Endif
        
        For i As Integer = 0 to UBound( this.file )
                If this.file(i).fileName = fname Then
                        ' We need to add sizeOf(datapackFile) since the offset
                        ' points to the record, not the file
                        If i = 0 Then
                                ' If it is the first file then the location is
                                ' in the header
                                Seek #this.fileHandle, this.header.firstOffset _
                                        + sizeOf(datapackFile)
                        Else
                                ' The offset is in the previous record
                                Seek #this.fileHandle, this.file(i-1).nextFile _
                                        + sizeOf(datapackFile)
                        Endif

                        ' Update the current file pointer
                        this.currentFile = @this.file(i)
                        
                        Return E_NO_ERROR
                Endif
        Next
        
        Return E_FILE_NOT_FOUND
End Function

Function datapack.extractFile( ByVal fname As String, ByVal outFileName As String ) As errorCode
        Dim As errorCode e = this.seekToFile(fname)
        
        ' Make sure the seek worked, and it already error checks some stuff
        If e Then
                Return e
        Endif
        
        ' Make sure that the seek set the pointer correctly
        If this.currentFile = 0 Then
                Return E_BAD_POINTER
        Endif
        
        ' Open the output file
        Dim As Integer hndl = FreeFile
        
        If hndl = 0 Then
                Return E_FILEIO_FAILED
        Endif
        
        Open outFileName For Binary As #hndl
        
        If err Then
                Return E_FILEIO_FAILED
        Endif

        ' Start extracting the data
        For i As UInteger = 0 to currentFile->fileSize/sizeOf(integer)
                Dim As Integer buffer
                
                Get #this.fileHandle,, buffer
                Put #hndl,, buffer
                
                ' Check for errors
                If err Then
                        Return E_FILEIO_FAILED
                Endif
                If eof(this.fileHandle) Then
                        Return E_FILE_ENDED_UNEXPECTEDLY
                Endif
        Next
        
        Close #hndl
        
        Return E_NO_ERROR
End Function

Function datapack.packFiles( ByVal directory As String, ByVal packFile As String ) As errorCode
        ' Make sure directory is a folder and exists
        Dim attr As Integer
        Dir (directory, &hFF, attr)
        
        If not (attr = &h10) then
                Return E_FILE_NOT_FOUND
        Endif
        
        ' Create a list of files
        Dim As String fileList(Any)
        Dim As String fName = Dir(directory & "/*", &h01 or &h20)
        
        Do Until fName = ""
                ' Add this file to the list
                Dim As Integer count = UBound(fileList)+1
                
                ReDim Preserve As String fileList(count)
                
                If UBound(fileList) <> count Then
                        Return E_RESIZE_FAILED
                Endif
                
                fileList(count) = fName
                
                ' Find the next file
                fName = dir()
        Loop
        
        ' Make sure there is stuff to archive
        If UBound(fileList) < 0 Then
                Return E_FILE_NOT_FOUND
        Endif
        
        ' Resize the file record array
        Dim As Integer count = UBound( fileList )
        ReDim Preserve this.file(count) As datapackFile
        
        If UBound(this.file) <> count Then
                Return E_RESIZE_FAILED
        Endif
        
        ' Update the header
        this.header.firstOffset = sizeOf(datapackHeader) + this.header.fileSpacing
        
        ' Open the file and start writing
        Dim As Integer hndl = FreeFile
        
        If hndl = 0 Then
                Return E_FILEIO_FAILED
        Endif
        
        Open packFile For Binary As #hndl
        
        ' write the header
        Put #hndl,, this.header
        
        ' Seek to the location of the first file
        Seek #hndl, this.header.firstOffset
        
        If err Then
                Return E_FILEIO_FAILED
        Endif
        
        ' Start writing files
        For i As Integer = 0 to count
                ' Open the file
                Dim As Integer inFile = FreeFile
                
                If inFile = 0 Then
                        Return E_FILEIO_FAILED
                Endif
                
                Open directory & "/" & fileList(i) For Binary As #inFile
                
                If err Then
                        Return E_FILEIO_FAILED
                Endif
                        
                
                ' Construct the file record
                this.file(i).fileName = fileList(i)
                this.file(i).fileSize = LoF(inFile)
                
                ' Calculate where the beginning of the next file will be
                If i < count Then
                        this.file(i).nextFile = this.file(i).fileSize + Seek(hndl) + _
                                sizeOf(datapackFile) + this.header.fileSpacing
                Else
                        ' There is no next file
                        this.file(i).nextFile = 0
                Endif
                
                ' Check nothing went wrong
                If this.file(i).fileSize = 0 Then
                        Return E_FILEIO_FAILED
                Endif
                
                ' Write the record
                Put #hndl,, this.file(i)
                
                ' Copy the file
                Do
                        Dim As Integer buffer
                        
                        Get #inFile,, buffer
                        Put #hndl,, buffer
                        
                        If err Then
                                Return E_FILEIO_FAILED
                        Endif
                Loop Until eof(inFile)
                
                Close #inFile
                
                ' Seek to the start of the next file
                If this.file(i).nextFile > 0 Then
                        Seek #hndl, this.file(i).nextFile
                Endif
        Next
        
        ' Write some buffer bytes at the end of the file
        For i As Integer = 0 to (this.header.fileSpacing/sizeOf(integer))
                Dim As Integer buffer = &hFF00FF00FF00FF00
                
                Put #hndl,, buffer
                
                If err Then
                        Return E_FILEIO_FAILED
                Endif
        Next
                
        
        ' Close the file
        Close #hndl
        
        Return E_NO_ERROR
End Function

Function datapack.openPack( ByVal fname As String ) As errorCode
        ' Make sure a file was specified and exists
        If fname = "" Then
                Return E_NO_FILE_SPECIFIED
        Endif
        
        If not FileExists(fname) Then
                Return E_NO_FILE_SPECIFIED
        Endif
        
        ' Open the file
        fileHandle = FreeFile
        
        If fileHandle = 0 Then
                Return E_FILEIO_FAILED
        Endif
        
        Open fname For Binary As #fileHandle
        
        If err Then
                Return E_FILEIO_FAILED
        Endif
        
        ' Get the header
        Get #fileHandle,, this.header
        
        If this.header.identifier <> &h0140 Then
                Return E_BAD_DATA
        Endif
        
        ' Read the file records
        Seek #fileHandle,header.firstOffset
        
        ' Empty the file records
        If UBound(this.file) > -1 Then
                ReDim this.file(-1) As datapackFile
        Endif
        
        Do
                ' Create a new file entry
                Dim As Integer count = UBound(this.file)+1
                
                ReDim Preserve this.file(count) As datapackFile
                
                ' Get the file record
                Get #fileHandle,, this.file(count)
                
                If err Then
                        Return E_FILEIO_FAILED
                Endif
                
                ' Seek to the next record if there is one
                If this.file(count).nextFile = 0 Then
                        ' There are no more files
                        Exit Do
                Else
                        Seek #fileHandle, this.file(count).nextFile
                Endif
        Loop Until eof(fileHandle)
        
        Return E_NO_ERROR
End Function

Function datapack.closePack() As errorCode
        If this.fileHandle Then
                Close #this.fileHandle
                this.fileHandle = 0
        Endif
        
        Return E_NO_ERROR
End Function
