<#
    .Synopsis
    Script for use in bamboo, to publish modules/ DSC Resources in internall PowerShell Gallery a.k.a. Artifactory.

    .Description
    Script is using Update-OPBambooModule function to publish modules to internal gallery.
    It has special trigger to publish only when called from master branch (to avoid publishing unfinished/not approved code).

    .Example
    Start-ModuleUpdate
    Uses default parameter values and publishes any module found in .\source\<Module>\<Module.psd1>
#>

[CmdletBinding()]
param (
    # Path to manifests of modules that should be published
    [String]$Path = '.\source\*\*.psd1',

    # URI to internal PowerShell Gallery
    [String]$ApiUri = 'http://artifactory.expertslive.local:8081/artifactory/api/nuget/powershell-gallery',

    # Version of Bamboo Functions module that should be imported/used
    [Version]$ModuleRequiredVersion = $env:bamboo_BambooModuleVersion,

    # API key that should be used for publishing modules
    [String]$ApiKey = $env:bamboo_ArtifactoryPassword
)

if ($env:bamboo_planRepository_branch -ne 'master') {
    Write-Host "On a branch $env:bamboo_planRepository_branch - not a master, skipping publish phase..."
    exit 0
}

Import-Module -Name BambooFunctions -RequiredVersion $ModuleRequiredVersion
foreach ($module in Get-ChildItem -Path $Path) {
    Write-Host "Publishing module $($module.Basename) to $ApiUri"
    Update-OPBambooModule -Path $module.FullName -ApiKey $ApiKey -ApiUri $ApiUri
}