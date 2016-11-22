<#
    .Synopsis
    Script for use in bamboo, to run Pester tests against code in the repo.

    .Description
    Script uses Pester to perform two types of tests:
    -- general modules (shared across all repositories)
    -- repository-specific tests (any tests found in "PesterTests" folder located in the folder specified by Path parameter)
    Results are stored in NUnit format so that bamboo can easily pick them up.

    .Example
    Start-PesterTest
    Uses default parameter values tests all the scripts/modules/DSC resources found in .\source
#>

[CmdletBinding()]
param (
    # Path to the scripts/modules/DSC resources that should be tested
    [String]$Path = '.\source',

    # Path to data file that contains definition for test tags that should be excluded for the given repo
    [String]$ExcludeFilePath = '.\PesterTests\ExcludedTags.psd1'
)

$generalTestsPath = "$PSScriptRoot\Tests"
Set-Location -LiteralPath $Path
$null = New-Item -ItemType Directory -Name test-reports -Force
$invokePesterParam = @{
    Script = "$generalTestsPath\*.Tests.ps1" 
    OutputFormat = 'NUnitXml' 
    OutputFile = '.\test-reports\GeneralTests.xml'
}

if (Test-Path -LiteralPath $ExcludeFilePath -PathType Leaf) {
    $data = Import-PowerShellDataFile -LiteralPath $ExcludeFilePath
    $excludeTag = 
        foreach ($key in $data.Keys) { 
            foreach ($item in $data.$key) { 
                "$key`:$item" 
            }
        }
    if ($excludeTag) {
        $invokePesterParam.ExcludeTag = $excludeTag
    }
}

Invoke-Pester @invokePesterParam

if (Test-Path -LiteralPath .\PesterTests -PathType Container) {
    foreach ($testFile in Get-ChildItem -Path .\PesterTests\*.Tests.ps1) {
        $outFile = '.\test-reports\{0}.xml' -f ($testfile.Basename -replace '[^a-z]')
        Invoke-Pester -Script $testFile.FullName -OutputFormat NUnitXml -OutputFile $outFile
    }
}