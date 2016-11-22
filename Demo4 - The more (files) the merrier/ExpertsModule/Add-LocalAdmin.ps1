Function Add-LocalAdmin {
    param (
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
        ([ADSI]"WinNT://$ComputerName/Administrators,group").Add("WinNT://$Domain/$Identity")
    }
    Catch {
        Throw "Failed to add $Domain\$Identity to Administrators group on $ComputerName. Error: $_"
    }
}
