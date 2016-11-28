#region Un-mergable branch
Get-OPGitPullRequest -Repository bamboo-branches | ft
Get-OPGitPullRequest -Repository bamboo-branches -OutVariable toMerge | Merge-OPGitPullRequest
$toMerge.Show()
$toMerge | mepr
#endregion

#region bamboo traffic lights
Start-Process http://bamboo.expertslive.local:8085/browse/EL-BB/branches
Start-Process http://bamboo.expertslive.local:8085/browse/EL-BB1-JOB1-6/test/case/4259905
Start-Process http://bitbucket.expertslive.local:7990/projects/EL/repos/bamboo-branches/settings/pull-requests
$showBamboo = $true
#endregion

#region No one...
Show-Logo NextDemo -Width 800
psedit C:\Git\Demo8.ps1
Clear-Host
#endregion
