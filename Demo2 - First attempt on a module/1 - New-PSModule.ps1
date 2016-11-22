$Path = 'C:\expertslive\Demo1 - Scripts from a UNC share'
$ModuleName = 'ExpertsModule'
$Destination = "C:\expertslive\Demo2 - First attempt on a module\$ModuleName"
$functionsToExport = $null

If(!(Test-Path $Destination -PathType Container)) {
    New-Item -ItemType Directory -Path $Destination
}

Get-ChildItem $Destination | Where-Object {$_.Extension -in @('.psd1','.psm1')} | Remove-Item

Foreach($file in (Get-ChildItem -LiteralPath $Path -Filter *.ps1)) {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile( 
        $file.FullName, 
        [ref]$null, 
        [ref]$Null 
    )

    Add-Content -LiteralPath "$Destination\$ModuleName.psm1" -Value "Function $($File.BaseName) {"
    Add-Content -LiteralPath "$Destination\$ModuleName.psm1" -Value $ast.Extent.Text
    Add-Content -LiteralPath "$Destination\$ModuleName.psm1" -Value "} `r`n"

    [string[]]$functionsToExport += $file.BaseName
}

New-ModuleManifest -Path "$Destination\$ModuleName.psd1" -ModuleVersion 1.0.0.0 -RootModule "$ModuleName.psm1" -Author ExpertsLive -CompanyName Optiver -FunctionsToExport $functionsToExport

$manifestContent = Get-Content "$Destination\$ModuleName.psd1"
Remove-Item -Path "$Destination\$ModuleName.psd1" -ErrorAction SilentlyContinue
$manifestContent | Add-Content -Path "$Destination\$ModuleName.psd1" -Encoding UTF8