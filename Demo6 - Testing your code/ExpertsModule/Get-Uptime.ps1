Function Get-Uptime {
<#
.SYNOPSIS
    Get the last boot up time of a (remote) Windows computer via CIM.
.DESCRIPTION
    Get the uptime and the boot uptime of a Windows computer. This function uses
    CIM to connect to the remote computer.
.EXAMPLE
    Get-Uptime -ComputerName Server

    Get's the uptime for computername Server
#>

  param(
    # Target host or hosts to retrieve the last boot up time for.
    [Parameter(Mandatory=$false)]
    [string[]] $ComputerName = 'localhost',

    # The credential used to connect to the remote host
    [pscredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty
  )

  foreach ($Computer in $ComputerName) {

    Try {
        if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
            $cimSession = New-CimSession -Credential $Credential -ComputerName $ComputerName
        }
        else {
            $cimSession = New-CimSession -ComputerName $ComputerName
        }
    }
    Catch {
        Throw "Failed to create cim session to $ComputerName. Error: $_"
    }

    $CimHash = @{
        CimSession = $cimSession
        ErrorAction = 'Stop'
        ClassName = 'Win32_OperatingSystem'
    }

    try {
        if ($LastBootUpTime = Get-CimInstance @CimHash | Select-Object -ExpandProperty LastBootUpTime) {
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
        Write-Warning -Message "Failed to execute CIM query against ${Computer}: $($_.Exception.Message)"
    }
  }
}
