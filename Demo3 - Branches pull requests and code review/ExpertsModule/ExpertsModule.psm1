Function Add-LocalAdmin {
Param (
    # Name of the computer
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

Function New-Password {

    <#
    .Synopsis
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
    .DESCRIPTION
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
    .EXAMPLE
       New-OPPassword
       C&3SX6Kn

       Will generate one password with a length between 8  and 12 chars.
    .EXAMPLE
       New-OPPassword -MinPasswordLength 8 -MaxPasswordLength 12 -Count 4
       7d&5cnaB
       !Bh776T"Fw
       9"C"RxKcY
       %mtM7#9LQ9h

       Will generate four passwords, each with a length of between 8 and 12 chars.
    .EXAMPLE
       New-OPPassword -InputStrings abc, ABC, 123 -PasswordLength 4
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString
    .EXAMPLE
       New-OPPassword -InputStrings abc, ABC, 123 -PasswordLength 4 -FirstChar abcdefghijkmnpqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString that will start with a letter from 
       the string specified with the parameter FirstChar
    .OUTPUTS
       [String]
    .NOTES
       Written by Simon Wåhlin
       Edit by Daniël Both to match Optiver internal function standard naming.
    .FUNCTIONALITY
       Generates random passwords
    .LINK
       http://blog.simonw.se/powershell-generating-random-password-for-active-directory/
   
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='FixedLength',
        ConfirmImpact='None')]
    [OutputType([String])]
    Param
    (
        # Specifies minimum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({$_ -gt 0})]
        [Alias('Min')] 
        [int]$MinPasswordLength = 8,
        
        # Specifies maximum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({
                if($_ -ge $MinPasswordLength){$true}
                else{Throw 'Max value cannot be lesser than min value.'}})]
        [Alias('Max')]
        [int]$MaxPasswordLength = 12,

        # Specifies a fixed password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='FixedLength')]
        [ValidateRange(1,2147483647)]
        [int]$PasswordLength = 8,
        
        # Specifies an array of strings containing charactergroups from which the password will be generated.
        # At least one char from each group (string) will be used.
        [String[]]$InputStrings = @('abcdefghijkmnpqrstuvwxyz', 'ABCEFGHJKLMNPQRSTUVWXYZ', '23456789', '!"#%&'),

        # Specifies a string containing a character group from which the first character in the password will be generated.
        # Useful for systems which requires first char in password to be alphabetic.
        [String] $FirstChar,
        
        # Specifies number of passwords to generate.
        [ValidateRange(1,2147483647)]
        [int]$Count = 1
    )
    Begin {
        Function Get-Seed{
            # Generate a seed for randomization
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            $Random.GetBytes($RandomBytes)
            [BitConverter]::ToUInt32($RandomBytes, 0)
        }
    }
    Process {
        If($PSCmdlet.ShouldProcess('localhost','Generate new password')){
            For($iteration = 1;$iteration -le $Count; $iteration++){
                $Password = @{}
                # Create char arrays containing groups of possible chars
                [char[][]]$CharGroups = $InputStrings

                # Create char array containing all chars
                $AllChars = $CharGroups | ForEach-Object {[Char[]]$_}

                # Set password length
                if($PSCmdlet.ParameterSetName -eq 'RandomLength')
                {
                    if($MinPasswordLength -eq $MaxPasswordLength) {
                        # If password length is set, use set length
                        $PasswordLength = $MinPasswordLength
                    }
                    else {
                        # Otherwise randomize password length
                        $PasswordLength = ((Get-Seed) % ($MaxPasswordLength + 1 - $MinPasswordLength)) + $MinPasswordLength
                    }
                }

                # If FirstChar is defined, randomize first char in password from that string.
                if($PSBoundParameters.ContainsKey('FirstChar')){
                    $Password.Add(0,$FirstChar[((Get-Seed) % $FirstChar.Length)])
                }
                # Randomize one char from each group
                Foreach($Group in $CharGroups) {
                    if($Password.Count -lt $PasswordLength) {
                        $Index = Get-Seed
                        While ($Password.ContainsKey($Index)){
                            $Index = Get-Seed                        
                        }
                        $Password.Add($Index,$Group[((Get-Seed) % $Group.Count)])
                    }
                }

                # Fill out with chars from $AllChars
                for($i=$Password.Count;$i -lt $PasswordLength;$i++) {
                    $Index = Get-Seed
                    While ($Password.ContainsKey($Index)){
                        $Index = Get-Seed                        
                    }
                    $Password.Add($Index,$AllChars[((Get-Seed) % $AllChars.Count)])
                }
                Write-Output -InputObject $(-join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))
            }
        }
    }

} 

