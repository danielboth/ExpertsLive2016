Describe Get-Uptime {
  Mock -CommandName Get-CimInstance -MockWith {
    $cimInstance = [Microsoft.Management.Infrastructure.CimInstance]::new('win32_operatingsystem', 'root/cimv2')
    $cimInstance | Add-Member -MemberType NoteProperty -Name LastBootUptime -Value (Get-Date).AddDays(-10)
    return $cimInstance
  } -ModuleName ExpertsModule

  Mock -CommandName New-CimSession -MockWith {
    return [Microsoft.Management.Infrastructure.CimSession]::Create('Server',[Microsoft.Management.Infrastructure.Options.CimSessionOptions]::new())
  } -ModuleName ExpertsModule

  $fakeCredential = New-Object -TypeName  System.Management.Automation.PSCredential ('username',(ConvertTo-SecureString “PlainTextPassword” -AsPlainText -Force))

  Context 'Running with -ComputerName' {
    It 'Should not throw and call Get-CimInstance exactly one time when Get-Uptime is executed' {
      { Get-Uptime -ComputerName Server } | Should not throw
      Assert-MockCalled -CommandName Get-CimInstance -Times 1 -Exactly -ModuleName ExpertsModule -Scope It
      Assert-MockCalled -CommandName New-CimSession -Times 1 -Exactly -ModuleName ExpertsModule -Scope It
    }
  }

  Context 'Running with -ComputerName and Credential' {
    It 'Should not throw and call Get-CimInstance exactly one time when Get-Uptime is executed with Credentials' {
      { Get-Uptime -ComputerName Server -Credential $fakeCredential } | Should not throw
      Assert-MockCalled -CommandName Get-CimInstance -Times 1 -Exactly -ModuleName ExpertsModule -Scope It
      Assert-MockCalled -CommandName New-CimSession -Times 1 -Exactly -ModuleName ExpertsModule -Scope It
    }
  }

  Context 'Running without parameters' {
    It 'Property LastBootUpTime should return a datetime object' {
      (Get-Uptime).LastBootUpTime.GetType().Name | Should Be 'DateTime'
    }

    It 'Property Uptime should return a timespan object' {
      (Get-Uptime).Uptime.GetType().Name | Should Be 'TimeSpan'
    }

    It 'Uptime should be 10 days' {
      (Get-Uptime).Uptime.Days | Should Be 10
    }
  }
}