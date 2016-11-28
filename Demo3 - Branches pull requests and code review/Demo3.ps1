#region Repo and PR
Start-Process http://bitbucket.expertslive.local:7990/projects/EL/repos/demo3/browse
Get-OPGitPullRequest -Repository Demo3 | ForEach-Object Show
$showStash = $true
#endregion

#region split - why
Show-Logo JekyllAndHyde -Width 800
Get-OPGitPullRequest -Repository 'Jekyll-and-Hyde' | Format-Table
gpr Jekyll-and-Hyde | % show
Show-Logo MergeConflict -Width 600
#endregion
