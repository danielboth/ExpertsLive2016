function Add-Group {
    Param (
        $ComputerName,
        $Group
    )

    # I hope Dr Jekyll will fix this so that it doesn't throw expections...
    $localGroup = ([ADSI]"WinNT://$ComputerName").Create('Group',$Group)
    $localGroup.SetInfo()
    $localGroup.Description = 'Created with Add-Group function'
    $localGroup.SetInfo()

}
