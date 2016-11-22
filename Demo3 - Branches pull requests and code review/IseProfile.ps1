function Update-Logo {

    <#
        .Synopsis
        Updates logo created with Show-Logo function.

        .Example
        Update-Logo -Script { $logo.Image.Width = 150 }
        Modifies 'Width' property of Image to 150.
    #>

    param (
        [action]$Script,
        [hashtable]$Logo = $Global:Logo,
        [string]$Property = 'Image',
        [System.Windows.Threading.DispatcherPriority]$Priority = 'Normal'

    )
    $Logo.$Property.Dispatcher.Invoke(
        $Priority,
        $Script
    )
}


function Show-Logo {
    param (
        [ValidateSet(
            'JustDoGit1',
            'NextDemo',
            'JekyllAndHyde',
            'JustDoGit2',
            'BookCopyPaste',
            'MergeConflict',
            'WhatIsGit'
        )]
        [string]$Logo = 'WhatIsGit',
        [int]$Width = 400,
        [double]$Opacity = 0.8
    )

    $Info = [hashtable]::Synchronized(@{})
    $Info.LogoPaths = @{
        JekyllAndHyde = 'C:\Git\gitlab\Pictures\1445287639-JekyllandHyde_tickets-e1475322081757.jpg'
        MergeConflict = 'C:\Git\gitlab\Pictures\356merge-conflicts.jpg'
        WhatIsGit = 'C:\Git\gitlab\Pictures\git.png'
        JustDoGit1 = 'C:\Git\gitlab\Pictures\JustDoGit.png'
        JustDoGit2 = 'C:\Git\gitlab\Pictures\JustDoGit2.jpg'
        NextDemo = 'C:\Git\gitlab\Pictures\no_one_expects_the_spanish_inquisition_by_simzer-d5bxjqp.png'
        BookCopyPaste = 'C:\Git\gitlab\Pictures\SO-CopyPaste.jpg'
    }
    $Info.Width = $Width
    $Info.Opacity = $Opacity
    $Info.Logo = $Logo

    $newRunspace = [runspacefactory]::CreateRunspace()
    $newRunspace.ApartmentState = 'STA'
    $newRunspace.ThreadOptions = 'ReuseThread'          
    $newRunspace.Open()
    $newRunspace.SessionStateProxy.SetVariable(
        'syncHash',
        $Info
    )          
    $psCmd = [PowerShell]::Create().AddScript({   
            [xml]$XAML = @"
<Window 
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Width="600" Title="GuiTrick" SizeToContent="WidthAndHeight" 
    Name="Window" WindowStyle="None" AllowsTransparency="True"
	Background="Transparent" Topmost="True" >
    <Grid Background="Transparent">
        <Image Width="$($syncHash.Width)" Opacity="$($syncHash.Opacity)" Name="Logo">
		    <Image.Source>
			    <BitmapImage UriSource="$($syncHash.LogoPaths[$syncHash.Logo])" />
		    </Image.Source>
	    </Image>
	</Grid>
</Window>
"@
            $Reader = New-Object System.Xml.XmlNodeReader $XAML
            $syncHash.Logo = [Windows.Markup.XamlReader]::Load($Reader)
            $syncHash.Image = $syncHash.Logo.FindName('Logo')
            $syncHash.Logo.Add_MouseRightButtonDown({$this.Close()})
            $syncHash.Logo.Add_MouseLeftButtonDown({$this.DragMove()})
            $syncHash.Logo.ShowDialog() | Out-Null
    })
    $psCmd.Runspace = $newRunspace
    $data = $psCmd.BeginInvoke()
    $Info
}


$PSDefaultParameterValues = @{
    '*-OPGit*:Credential' = $cred
}

function Remove-CurrentFile {
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'Medium'
    )]
    param ()
    $fullPath = $psISE.CurrentFile.FullPath
    $null = $psISE.CurrentPowerShellTab.Files.Remove($psISE.CurrentFile)
    Remove-Item -LiteralPath $fullPath -Force
}

$restSplat = New-OPBasicAuthRestObject -Credential $cred
$bambooUri = 'http://bamboo.expertslive.local:8085/rest/api/latest'
$stashUri = 'http://bitbucket.expertslive.local:7990/rest/api/latest'
$plans = (Invoke-RestMethod @restSplat -Uri $bambooUri/project/EL?expand=plans).plans.plan.planKey.key
$myPlans = @{}
foreach ($key in $plans) {
    $myKey = Invoke-RestMethod @restSplat -Uri $bambooUri/plan/$key/branch | 
        ForEach-Object { $_.branches.branch } |
        Where-Object { $_.shortName -match '^bartek' } | 
        Sort-Object -Property shortName | 
        Select-Object -First 1 -ExpandProperty key

    $myPlans.Add(
        $key,
        $myKey    
    )
} 
$repos = (Invoke-RestMethod @restSplat -Uri $stashUri/projects/EL/repos).values.slug 
$showBamboo = $false
$showStash = $false

$promptConfig = [hashtable]::Synchronized(@{})
$promptConfig.planData = @()
$promptConfig.repoData = @()
$promptConfig.restSplat = $restSplat
$promptConfig.plans = $plans
$promptConfig.nickNames = $nickNames
$promptConfig.myPlans = $myPlans
$promptConfig.repos = $repos
$promptConfig.Stop = $false
$promptConfig.ApiDelay = 60
$promptConfig.LastUpdate = Get-Date

$runspace = [runspacefactory]::CreateRunspace()
$runspace.Open()
$runspace.SessionStateProxy.SetVariable('promptConfig', $promptConfig)
$powerShell = [powershell]::Create()
$powerShell.Runspace = $runspace

$null = $powerShell.AddScript{
    $bambooUri = 'http://bamboo.expertslive.local:8085/rest/api/latest'
    $stashUri = 'http://bitbucket.expertslive.local:7990/rest/api/latest'
    $icons = @{
        arrow = [char]0x27A0
        good = [char]0x2714
        bad = [char]0x2718
        clock = [char]0x23F0
        calendar = [char]::ConvertFromUtf32(0x0001F4C5)
        hourglass = [char]0x231B
        hand = [char]0x270D
    }
    $restSplat = $promptConfig.restSplat
    do {
        $promptConfig.planData = foreach ($plan in $promptConfig.plans) {
            $results = Invoke-RestMethod @restSplat -Uri $bambooUri/result/${plan}-latest
            try {
                $myResult = Invoke-RestMethod @restSplat -Uri $bambooUri/result/$($promptConfig.myPlans[$plan])-latest -ErrorAction SilentlyContinue
                $mainResult = $myResult
                $color = if ($results.successful) { 'DarkGreen' } else { 'Red' }
            } catch {
                $mainResult = $results
                $color = 'Red'
            }
            $lastBuildDate = [datetime]$mainResult.buildCompletedDate
            $dateFormat, $timeIcon = if ((New-TimeSpan -Start $lastBuildDate).Days) {
                'dd-MMM'
                $icons.calendar
            } else {
                'HH:mm'
                $icons.clock
            }

            @{
                text = '{0} ({1}): ' -f $mainResult.key, $results.buildNumber
                color = 'DarkBlue'
                separator = ''
            },
            

            @{
                text = '{0} {1} {2} {3}:{4}' -f @(
                    $timeIcon,
                    $lastBuildDate.ToString($dateFormat),
                    $icons.arrow,
                    $(if ($mainResult.successful) { $icons.good } else { $icons.bad } ),
                    $(if ($mainResult.successful) { $mainResult.successfulTestCount } else { $mainResult.failedTestCount })
                    
                )
                color = $color
                separator = ' :: '
            }
        }
    
        $promptConfig.repoData = foreach ($repo in $promptConfig.repos) {
            $repoName = (Invoke-RestMethod @restSplat -Uri $stashUri/projects/EL/repos/$repo).Name
            $pulls = foreach ($result in (Invoke-RestMethod @restSplat -Uri $stashUri/projects/EL/repos/$repo/pull-requests).values) {
                switch ($result.author.user.name) {
                    BartekB {
                        $icon = $icons.hourglass
                        $person = 'Me'
                        $role = 'author'
                    }
                    default {
                        $icon = $icons.hand
                        $person = $_
                        $role = 'author'
                    }
                }

                $approved = $false
                if ($result.reviewers) {
                    foreach ($review in $result.reviewers) {
                        if ($review.approved) {
                            $approved = $true
                            $person = switch ($review.user.name) {
                                BartekB {
                                    'Me'
                                }
                                default {
                                    $_
                        
                                }
                            }
                            $role = 'reviewer'
                            $icon = $icons.good
                        }
                    }
                } else {
                    # because Alexander likes to leave it blank... :(
                    foreach ($review in $result.participants) {
                        if ($review.approved) {
                            $approved = $true
                            $person = switch ($review.user.name) {
                                BartekB {
                                    'Me'
                                }
                                default {
                                    $_
                        
                                }
                            }
                            $role = 'reviewer'
                            $icon = $icons.good
                        }
                    }
                }
                if (-not $person) {
                    $person = 'UNKNOWN'
                    $role = 'UNKNOWN'
                }

                @{
                    text = '{0} [{1}:{2}] ({3})' -f @(
                        $icon,
                        $person,
                        $role,
                        $(
                            if ($commentCount = $result.properties.commentCount) {
                                'Comments: {0}' -f $commentCount 
                            } else {
                                'No Comments'
                            }
                        )
                    )
                    color = if ($approved) { 'DarkGreen' } else { 'DarkRed' }
                }
            }
            $branch = foreach ($result in (Invoke-RestMethod @restSplat -Uri $stashUri/projects/EL/repos/$repo/branches?details=true).values) {
                if ($result.displayId -in 'bartek','DrJekyll' -and ($ahead = $result.metadata.'com.atlassian.bitbucket.server.bitbucket-branch:ahead-behind-metadata-provider'.ahead)) {
                    @{
                        text = "[+$ahead]"
                        color = 'DarkCyan'
                    }
                }
            }
            if ($pulls -or $branch) {
                @{
                    text = $repoName
                    color = 'DarkBlue'
                }
                $branch
                $pulls
            }
        }
        $promptConfig.LastUpdate = Get-Date
        Start-Sleep -Seconds $promptConfig.ApiDelay
    } until ($promptConfig.Stop)

}
$handle = $powerShell.BeginInvoke()


$SOTList = Get-Content $profile\..\Snoverism.txt
New-Alias -Force -Name _ -Value Write-Host

function prompt {

    _ -n '<# ' -f Black
    _ -n 'Path: ' -f DarkCyan
    _ -n "$pwd " -f DarkBlue
    _ -n ':: ' -f Black
    _ -n 'Provider: ' -f DarkCyan
    _ -n $pwd.Provider.Name -f DarkBlue
    _ -n ' :: ' -f Black
    _ -n $env:USERDOMAIN -f DarkCyan
    _ -n '\' -f Black
    _ -n $env:USERNAME -f DarkCyan
    _ -n ' @ ' -f Black
    _ -n $env:COMPUTERNAME -f DarkBlue
    _ -n ' :: ' -f Black
    _ -n 'SOTLine: ' -f DarkCyan
    _ ($SOTList | Get-Random) -f DarkBlue
    if ($showBamboo) {
        _ -n 'Bamboo Plans: ' -f DarkCyan
        foreach ($result in $promptConfig.planData) {
            _ -n $result.text -f $result.color
            _ -n $result.separator -f Black
        }
        _ ' ' -f Black
    }
    
    if ($showStash -and $promptConfig.repoData) {
        _ -n 'Git Ahead/PR: ' -f DarkCyan
        foreach ($pr in $promptConfig.repoData) {
           _ -n $pr.text -f $pr.color
            _ -n ' :: ' -f Black
        }
        _ ' ' -f Black
    }
    _ -n ' #>' -f Black
    return "$("$([char]8288)"*3) "
}

New-Alias -name notepad++ -Value 'C:\Program Files (x86)\Notepad++\notepad++.exe' -Force

try {
    Import-Module ISEGit -ErrorAction Stop
    Enable-ISEGitPrompt
    Set-GitPrompt -Scheme Dark
} catch {
    Write-Warning 'No ISEGit for you!'
}

try {
    Start-Steroids
} catch {
    Write-Warning 'Suffer w/o coolest ISE addon EVER!'
}

