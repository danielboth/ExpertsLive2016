Foreach($file in (Get-ChildItem $PSScriptRoot -Filter *.ps1)) {
. $file.fullname
}

$Global:ExecutionContext.SessionState.InvokeCommand.PostCommandLookupAction = {
    [System.Diagnostics.DebuggerHidden()]
    param (
        [String]$CommandName,
        [System.Management.Automation.CommandLookupEventArgs]$CommandLookupEventArgs
    )
    
    if ($CommandLookupEventArgs.CommandOrigin -ne 'Runspace' -or
        $CommandLookupEventArgs.Command.ModuleName -ne 'ExpertsModule' -or
        $CommandName -eq 'Get-OPGalleryModuleVersion'
    ) {
        return
    }

    $currentModuleVersion = $CommandLookupEventArgs.Command.Module.Version
    $currentModuleName = $CommandLookupEventArgs.Command.Module.Name

    $galleryVersion = Get-OPGalleryModuleVersion -Module $CommandLookupEventArgs.Command.Module
    
    if ($currentModuleVersion -ge $galleryVersion) {
        return
    }

    if ($CommandName -match '^(Get|Test)') {
        Write-Warning "Version of $currentModuleName is outdated ($currentModuleVersion) - skipping update to $galleryVersion for Get/Test commands. Please update module manually."
        return
    } else {
        Write-Warning "Version of $currentModuleName is outdated ($currentModuleVersion) - attempting to install $galleryVersion"
        $CommandLookupEventArgs.CommandScriptBlock = {}
    }

    if (
        -not (Get-InstalledModule -Name $currentModuleName -ErrorAction SilentlyContinue 3> $null) -and
        -not (Get-PSRepository -Name Artifactory -ErrorAction SilentlyContinue)
    ) {
        Write-Debug "No way to update/install module $currentModuleName"
        return
    }

    $installedModule = Get-InstalledModule -Name $currentModuleName -ErrorAction SilentlyContinue
    $moduleRepository = Get-PSRepository -Name $installedModule.Repository -ErrorAction SilentlyContinue
    if ($installedModule -and -not $moduleRepository) {
        Write-Debug "Module $currentModuleName installed from inaccessible repository"
        return
    }

    try {
        Invoke-WebRequest -UseBasicParsing -Uri $moduleRepository.SourceLocation -ErrorAction Stop
    } catch {
        Write-Debug "Couldn't connect to $($moduleRepository.SourceLocation) - $_"
        return
    }
        
    try {
        $sharedParams = @{
            Name = $currentModuleName 
            RequiredVersion = $galleryVersion 
            Force = $true 
            ErrorAction = 'Stop'
        }
        Update-Module @sharedParams
    } catch {
        switch ($_.FullyQualifiedErrorId) {
            'ModuleNotInstalledOnThisMachine,Update-Module' {
                try {
                    Install-Module @sharedParams -Repository Artifactory
                } catch {
                    switch ($_.FullyQualifiedErrorId) {
                        'InstallModuleNeedsCurrentUserScopeParameterForNonAdminUser,Install-Module' {
                            try {
                                Install-Module @sharedParams -Scope CurrentUser -Repository Artifactory
                            } catch {
                                throw "Failed to install module even in the CurrentUser scope - $_"
                            }
                        }
                        default {
                            throw "Not recognized error ID when attempting to install module: $_"
                        }
                    }
                }
            }
            'AdminPrivilegesAreRequiredForUpdate,Update-Module' {
                try {
                    Install-Module @sharedParams -Scope CurrentUser -Repository Artifactory
                } catch {
                    throw "Failed to install module even in the CurrentUser scope - $_"
                }
            }
            default {
                throw "Not recognized error ID when attempting to update module: $_"
            }
        }
    }

    Remove-Module -Force -FullyQualifiedName @{ 
        ModuleName = $currentModuleName
        ModuleVersion = $currentModuleVersion 
    }
    Import-Module -Force -FullyQualifiedName @{ 
        ModuleName = $currentModuleName
        ModuleVersion = $galleryVersion 
    } -Scope Global

    Write-Warning "New version $galleryVersion of module $currentModuleName was imported, your command was NOT issued yet, please reissue your command!"
}