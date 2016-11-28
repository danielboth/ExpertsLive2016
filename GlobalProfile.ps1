$cred = Import-Clixml -Path $profile\..\Cred.xml
function New-Credential {
    [OutputType([pscredential])]
    param (
        [Parameter(Mandatory)]
        [String]$User,
        [Parameter(Mandatory)]
        [String]$Password
    )
    [pscredential]::new(
        $User,
        (ConvertTo-SecureString -AsPlainText -Force -String $Password)
    )
}

$adUserSearch = {
    param (
        [String]$CommandName,
        [String]$ParameterName,
        [String]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )
    ([ADSISearcher]"(&(objectClass=user)(samAccountName=$WordToComplete*))").FindAll() |
        ForEach-Object {
            $user = $_.GetDirectoryEntry()
            [System.Management.Automation.CompletionResult]::new(
                $user.sAMAccountName,
                $user.sAMAccountName,
                [System.Management.Automation.CompletionResultType]::ParameterValue,
                "User repository with source $($user.Name)"
            )
        }
}

Register-ArgumentCompleter -CommandName New-OPGitPullRequest -ParameterName Reviewers -ScriptBlock $adUserSearch

Register-ArgumentCompleter -CommandName Find-Module, Install-Module -ParameterName Repository -ScriptBlock {
    param (
        [String]$CommandName,
        [String]$ParameterName,
        [String]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )
    Get-PSRepository -Name "$WordToComplete*" | Sort-Object -Property Name | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.Name,
            $_.Name,
            [System.Management.Automation.CompletionResultType]::ParameterValue,
            "$($_.InstallationPolicy) repository with source $($_.SourceLocation)"
        )
    }
}

Register-ArgumentCompleter -CommandName Find-Module, Install-Module -ParameterName Name -ScriptBlock {
    param (
        [String]$CommandName,
        [String]$ParameterName,
        [String]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )
    $params = @{}
    if ($FakeBoundParameters['Repository']) {
        $params.Repository = $FakeBoundParameters['Repository']
    }
    Find-Module @params -Name "$WordToComplete*" | Sort-Object -Property Name | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.Name,
            $_.Name,
            [System.Management.Automation.CompletionResultType]::ParameterValue,
            "$($_.Description)"
        )
    }
}

Register-ArgumentCompleter -CommandName Update-Module -ParameterName Name -ScriptBlock {
    param (
        [String]$CommandName,
        [String]$ParameterName,
        [String]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )

    Get-InstalledModule -Name "$WordToComplete*" | Sort-Object -Property Name | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.Name,
            $_.Name,
            [System.Management.Automation.CompletionResultType]::ParameterValue,
            "$($_.Description)"
        )
    }
}

Register-ArgumentCompleter -CommandName Get-OPGitPullRequest, New-OPGitPullRequest, Merge-OPGitPullRequest, Get-OPGitBranch -ParameterName Repository -ScriptBlock {
    param (
        [String]$CommandName,
        [String]$ParameterName,
        [String]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )
    $cred = $FakeBoundParameters['Credential']
    if (-not $cred) {
        foreach ($key in $PSDefaultParameterValues.Keys) {
            $command, $param = $key.Split(':')
            if ('Credential' -like $param -and $CommandName -like $command) {
                $cred = $PSDefaultParameterValues.$key
            }
        }
    }
    if (-not $cred) {
        return
    }
    $restSplat = New-OPBasicAuthRestObject -Credential $cred
    $stashUri = 'http://bitbucket.expertslive.local:7990/rest/api/latest'
    (Invoke-RestMethod @restSplat -Uri $stashUri/projects/EL/repos).values | 
        Where-Object { $_.slug -like "$WordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.slug,
            $_.slug,
            [System.Management.Automation.CompletionResultType]::ParameterValue,
            "$($_.name) in $($_.project.name)"
        )
    }
}
Register-ArgumentCompleter -CommandName New-OPGitPullRequest -ParameterName SourceBranch -ScriptBlock {
    param (
        [String]$CommandName,
        [String]$ParameterName,
        [String]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [System.Collections.IDictionary]$FakeBoundParameters
    )

    $repo = $FakeBoundParameters['Repository']
    $cred = $FakeBoundParameters['Credential']
    if (-not $cred -or -not $repo) {
        foreach ($key in $PSDefaultParameterValues.Keys) {
            $command, $param = $key.Split(':')
            if ($CommandName -like $command) {
                if ('Credential' -like $param) {
                    $cred = $PSDefaultParameterValues.$key
                } elseif ('Repository' -like $param) {
                    $repo = $PSDefaultParameterValues.$key
                }
            }
        }
    }
    if (-not $cred -or -not $repo) {
        return
    }
    $restSplat = New-OPBasicAuthRestObject -Credential $cred
    $stashUri = 'http://bitbucket.expertslive.local:7990/rest/api/latest'
    (Invoke-RestMethod @restSplat -Uri $stashUri/projects/EL/repos/$repo/branches).values | 
        Where-Object { $_.displayId -like "$WordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_.displayId,
            $_.displayId,
            [System.Management.Automation.CompletionResultType]::ParameterValue,
            "$($_.displayId) in $repo"
        )
    }
}
