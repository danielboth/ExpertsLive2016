function Add-Group {
    <#
        .Synopsis
        Adds local groups.

        .Description
        Adds specified user to the local group.

        .Example
        Add-Group -ComputerName localhost -Group Test
        Adds group Test to localhost.
    #>
    
    Param (
        # Name of the computer
        [String]$ComputerName = $env:COMPUTERNAME,
        
        # Name of the group that should be added
        [Parameter(Mandatory)]
        [String]$Group
    )

    $localGroup = ([ADSI]"WinNT://$ComputerName").Create('Group',$Group)
    $localGroup.SetInfo()
    $localGroup.Description = 'Created with Add-Group function'
    $localGroup.SetInfo()

}
