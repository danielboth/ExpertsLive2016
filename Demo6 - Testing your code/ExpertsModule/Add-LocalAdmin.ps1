Function Add-LocalAdmin {
<#
.SYNOPSIS
    Add users to local administrator group on a (remote) computer.
.DESCRIPTION
    This function uses ADSI to add users or groups from Active Directory to the local administrators group on a computer.
.EXAMPLE
    Add-LocalAdmin -ComputerName server1 -Identity daniel
    
    Adds the user daniel to the local admin group on server1.      
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'Medium'
    )]
    Param (
        # Name of the computer, defaults to localhost.
        [Parameter()]
        [string]$ComputerName = $env:COMPUTERNAME,

        # The name of the domain in which the Identity exists
        [Parameter()]
        [string]$Domain = $env:USERDNSDOMAIN,

        # Name of the user or group to add to the local administrators group
        [Parameter(Mandatory)]
        [string]$Identity
    )

    Try {
        If($PSCmdlet.ShouldProcess("$ComputerName","Add identity $Domain\$Identity to local administrator group")){
            ([ADSI]"WinNT://$ComputerName/Administrators,group").Add("WinNT://$Domain/$Identity")
        }
    }
    Catch {
        Throw "Failed to add $Domain\$Identity to Administrators group on $ComputerName. Error: $_"
    }
}
