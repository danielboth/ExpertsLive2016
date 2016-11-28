#region Split module - how
psedit 'C:\Git\gitlab\Demo4 - The more (files) the merrier\1 - Split-Module.ps1'
#endregion

#region Split module - result
Get-OPGitPullRequest module-split | foreach show
Get-OPGitPullRequest module-split | Merge-OPGitPullRequest
#endregion
