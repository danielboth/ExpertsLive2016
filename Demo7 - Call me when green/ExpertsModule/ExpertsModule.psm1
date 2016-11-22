Foreach($file in (Get-ChildItem $PSScriptRoot -Filter *.ps1)) {
    . $file.fullname
}

