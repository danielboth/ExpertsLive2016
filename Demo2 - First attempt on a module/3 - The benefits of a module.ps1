$ModuleName = 'ExpertsModule'
$Destination = "C:\expertslive\Demo2 - First attempt on a module\$ModuleName"

Import-Module "$destination\$ModuleName.psd1"
Get-Command -Module $ModuleName

Get-Module -Name $ModuleName | Remove-Module

Import-Module "$destination\$ModuleName.psd1" -Prefix 'OP'
Get-Command -Module $ModuleName

Get-Command -Name Get-OPUptime -Syntax
Get-Command -Name Get-OPUptime -ShowCommandInfo
