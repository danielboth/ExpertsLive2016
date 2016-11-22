Function Get-Uptime {
<#
.SYNOPSIS
    Get the last boot up time of a (remote) Windows computer via CIM.
    
#>

param(
    # Target host or hosts to retrieve the last boot up time for.
    [Parameter(Mandatory=$false)]
    [string[]] $ComputerName = 'localhost',

    # The credential used to connect to the remote host
    [pscredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty)

foreach ($Computer in $ComputerName) {
    $CimHash = @{
        ComputerName = $Computer
        ErrorAction = 'Stop'
        ClassName = 'Win32_OperatingSystem'
    }
    if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
        $CimHash.Credential = $Credential
    }
    try {
        if ($LastBootUpTime = Get-CimInstance @CimHash | Select -ExpandProperty LastBootUpTime -ErrorAction SilentlyContinue) {
            New-Object PSObject -Property @{
                ComputerName = $Computer
                LastBootUpTime = $LastBootUpTime
                UpTime = [datetime]::Now - $LastBootUpTime
            }
        }
        else {
            Write-Warning -Message "Failed to retrieve last boot up time for $Computer (unknown failure)."
        }
    }
    catch {
        Write-Warning -Message "Failed to execute WMI query against ${Computer}: $($_.Exception.Message)"
    }
}

}
