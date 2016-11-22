param (
    [String]$ModuleName = '*',
    [String]$FunctionName = '*'
)

# PSScriptAnalyzer rules included in module test.
$AnalyzerRules = @(
    'PSUseDeclaredVarsMoreThanAssigments',
    'PSUsePSCredentialType', 
    'PSUseSingularNouns', 
    'PSUseOutputTypeCorrectly',
    'PSUseApprovedVerbs'
)

foreach ($file in Get-ChildItem -Path ".\$ModuleName\$ModuleName.psd1") {
    
    if ($file.Basename -ne $file.Directory.Name) {
        continue
    }
    
    Describe "Testing module $($file.Basename)" {
        It 'Can be imported without errors' {
            { Import-Module $file.FullName -ErrorAction Stop } | Should Not Throw
        }
    
        Foreach($function in (Get-Command -Module $file.Basename | Where-Object Name -Like $FunctionName)){
            Context "Testing function $($function.Name) defined in module $($file.Basename)" {

                $AST = [System.Management.Automation.Language.Parser]::ParseFile( 
                    "$($file.Directory.FullName)\$($function.Name).ps1", 
                    [ref]$null, 
                    [ref]$Null 
                )

                $Functions  = $Ast.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]},$true) 
                $Commands   = $Ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]},$true) 
                $Parameters = $Ast.FindAll({$args[0] -is [System.Management.Automation.Language.ParameterAst]},$true)
                $Variables  = $Ast.FindAll({$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]},$true)
            
                $functionHelp = Get-Help $function.Name
                $cmdProperties = Get-Command $function.Name

                It 'Has help description' {
                    $functionHelp.Description | Should not be $null
                }
                
                $functionHelp.parameters.parameter | Where-Object {$_.Name -notin 'WhatIf','Confirm'} | ForEach-Object {
                    It "Help description for parameter $($_.Name) is set" {
                        $_.Description | Should not be $null
                    }
                }
                
                It 'Has help examples' {
                    $functionHelp.Examples | Should not be $null
                }
                
                It 'Uses CmdletBinding' {
                    $cmdProperties.CmdletBinding | Should be $True
                }

                If($cmdProperties.Verb -in 'New','Remove','Set','Stop') {
                    It 'Should support WhatIf' {
                        $cmdProperties.Parameters['WhatIf'] | Should be $True
                    }
                }
                
                # Test the parameters defined in the function, parameters from subfunctions are not evaluated.
                $FunctionParameters = ($Functions | Where-Object{$_.Name -eq $($function.Name)}).Body.FindAll({$args[0] -is [System.Management.Automation.Language.ParameterAst]},$false)
                $FunctionParameters | ForEach-Object {
                    $ParameterName = $_.Name.VariablePath.UserPath
                    If(-not($Variables | Where-Object{$_.VariablePath.UserPath -eq 'PSBoundParameters'}).Splatted) {
                        It "Uses parameter $ParameterName in code" {
                            (($Variables.VariablePath.UserPath | Where-Object {$_ -eq $ParameterName}) | Measure-Object).Count -ge 2 | Should be $True
                        }
                    }

                    It "Has a datatype assigned to parameter $ParameterName" {
                            $_.Attributes | Where-Object{$_.psobject.properties.name -notcontains 'NamedArguments'} | Should not be $null
                    }
                }

                Foreach($Rule in $AnalyzerRules) {    
                    It "Should pass analyzer rule $Rule" {
                        $TestResults = Invoke-ScriptAnalyzer -Path "$($file.Directory.FullName)\$($function.Name).ps1" -IncludeRule $Rule
                        if ($testResults) {
                            throw ("Found {0} issues:`n{1}" -f $testResults.Count, ($testResults.Foreach{ "Line: $($_.Line) - $($_.Message) " } -join "`n"))
                        }
                    }
                }
            }
        }
    }
}