Describe 'New-Password' {

  Context 'Running without arguments'   {
    It 'runs without errors' {
      { New-Password } | Should Not Throw
    }
    
    It 'Should generate a unique password' {
      (New-Password) -eq (New-Password) | Should be $false
    }
  }
  Context 'Running with parameters' {
    It 'Should generate a 24 character password' {
      (New-Password -MinPasswordLength 24 -MaxPasswordLength 24).Length | Should be 24
    }

    It 'Password starts with letter A' {
      (New-Password -FirstChar A).ToCharArray()[0] | Should be 'A'
    }

    It 'Generates 4 passwords' {
      (New-Password -Count 4 | Measure-Object).Count | Should be 4
    }

    It 'The password only contains the characters xyz123!@#' {
      (New-Password -InputStrings 'xyz123!@#').ToCharArray() | ForEach-Object {$_ -in @('x','y','z','1','2','3','!','@','#') | Should be $true}
    }
  }
}
