$ModuleName = 'ExpertsModule'
$ModuleLocation = "C:\expertslive\Demo3 - Branches, pull requests and code review\$ModuleName"
$Destination = "C:\expertslive\Demo4 - The more (files) the merrier\$ModuleName"

If(!(Test-Path $Destination -PathType Container)) {
    New-Item -ItemType Directory -Path $Destination
}

Get-ChildItem $Destination | Remove-Item

$AST = [System.Management.Automation.Language.Parser]::ParseFile( 
    "$ModuleLocation\$ModuleName.psm1", 
    [ref]$null, 
    [ref]$Null 
)

$Functions  = $Ast.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]},$false) 

$Functions | ForEach-Object {
    $FunctionName = $_.Name
    $Code = $_.Extent.Text

    Add-Content -Path "$Destination\$FunctionName.ps1" -Value $Code
} 

# Copy the manifest file
Copy-Item -Path "$ModuleLocation\$ModuleName.psd1" -Destination $Destination

# Create a new PowerShell Module file which dot sources the functions defined in the new files.
$Content = 'Foreach($file in (Get-ChildItem $PSScriptRoot -Filter *.ps1)) {
    . $file.fullname
}
'

Add-Content -Path "$Destination\$ModuleName.psm1" -Value $Content