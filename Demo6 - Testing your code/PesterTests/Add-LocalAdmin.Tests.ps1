Describe Add-LocalAdmin {
  
  Context 'Running with -Whatif' {
    It 'Should not throw' {
      { Add-LocalAdmin -ComputerName Server -Domain 'expertslive.local' -Identity Expert -WhatIf } | Should not throw
    }
  }
}