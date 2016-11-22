param (
    # Name of the script that should be tested
    [String]$ScriptPath = '.\*.ps1',

    # PSScriptAnalyzer rules included in module test.
    $AnalyzerRules = @(
        'PSUseDeclaredVarsMoreThanAssigments',
        'PSUsePSCredentialType', 
        'PSUseSingularNouns', 
        'PSUseOutputTypeCorrectly', 
        'PSAvoidUsingWMICmdlet', 
        'PSUseApprovedVerbs'
    )
)

foreach ($file in Get-ChildItem -Path $ScriptPath -Recurse) {
    
    <# 
        Assumptions:
        -- scripts that are used as stand-alone tools
        -- not a part of module ($file.Directory does not contain $($file.Directory.Name).psd1
        -- not a test (.Tests.ps1)
        -- no scripts used for special purpose (like endpoint configuration)
        Excluding these from our tests... everything else should behave like a proper command.
    #>

    $parent = $file.Directory
    $wannabeManifest = '{0}\{1}.psd1' -f $parent.FullName, $parent.Name
    
    if (Test-Path -Path $wannabeManifest -PathType Leaf) {
        Write-Host "Skipping file $($file.FullName) - looks like a part of a module $wannabeManifest"
        continue
    }
    
    if ($file.Name -like '*.Tests.ps1') {
        Write-Host "Skipping file $($file.FullName) - looks like test script"
        continue
    }

    if ($foundString = Select-String -Pattern 'LanguageMode.*=.*NoLanguage' -Path $file.FullName) {
        Write-Host "Skipping file $($file.FullName) - looks like constrained endpoint (line: $($foundString.Line))"
        continue
    }

    if (($configuration = Select-String -Pattern '^configuration' -Path $file.FullName) -and $file.Name -NotMatch '-') {
        Write-Host "Skipping file $($file.FullName) - looks like partial configuration (line: $($configuration.Line))"
        continue
    }

    #region No skip - define variables shared accross tests
    $cmd = Get-Command -Name $file.FullName
    if ($cmd.ScriptBlock) {
        $scriptHelp = Get-Help $file.FullName
    } else {
        $scriptHelp = ''
    }
    $cmdletBinding = $cmd.ScriptBlock.Attributes |
        Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] }

    Describe "Testing script $($file.Basename) - general" -Tags "$($file.Name):General" {
        It 'Should have scriptblock property set' {
            $cmd.ScriptBlock | Should not BeNullOrEmpty
        }

        It 'Uses CmdletBinding' {
            $cmdletBinding | Should not BeNullOrEmpty
        }
    }

    Describe "Testing help for script $($file.Basename)" -Tags "$($file.Name):Help" {
        It 'Has help description' {
            $scriptHelp.Description | Should not be $null
        }
                
        $scriptHelp.parameters.parameter | Where-Object {$_.Name -notin 'WhatIf','Confirm'} | ForEach-Object {
            if ($_.Name) {
                It "Help description for parameter $($_.Name) is set" {
                    $_.Description | Should not be $null
                }
            }
        }
                
        It 'Has help examples' {
            $scriptHelp.Examples | Should not be $null
        }
    }
                
    Describe "Testing script $($file.Basename) for verb/noun rules" -Tags "$($file.Name):VerbNoun" {
        $verb, $noun = $file.Basename -split '-'

        If($verb -in 'New','Remove','Set','Stop') {
            It 'Should SupportShouldPRocess' {
                $cmdletBinding.SupportsShouldProcess | Should be $True
            }
        }

        It "Verb ($verb) should be one of the approved verbs" {
            Get-Verb -verb $verb | Should not BeNullOrEmpty
        }

        It "Noun $($noun -join '-') should exist and not have '-' in it" {
            @($noun).Count | Should be 1
        }
    }
    
    Describe "Testing script $($file.Basename) for parameters definition/usage" -Tags "$($file.Name):Parameters" {
        # Test the parameters defined in the function, parameters from subfunctions are not evaluated.
        $scriptParameters = $cmd.ScriptBlock.Ast.FindAll(
            {$args[0] -is [System.Management.Automation.Language.ParameterAst]},
            $false
        )
        $scriptVariables =  $cmd.ScriptBlock.Ast.FindAll(
            {$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]},
            $false
        )

        $scriptParameters | ForEach-Object {
            $ParameterName = $_.Name.VariablePath.UserPath
            If(-not($scriptVariables | Where-Object{$_.VariablePath.UserPath -eq 'PSBoundParameters'}).Splatted) {
                It "Uses parameter $ParameterName in code" {
                    (($scriptVariables.VariablePath.UserPath | Where-Object {$_ -eq $ParameterName}) | Measure-Object).Count -ge 2 | Should be $True
                }
            }

            It "Has a datatype assigned to parameter $ParameterName" {
                    $_.Attributes | Where-Object{$_.psobject.properties.name -notcontains 'NamedArguments'} | Should not be $null
            }
        }
    }

    Describe "Testing PSScriptAnalyzer rules on $($file.BaseName)" -Tags "$($file.Name):ScriptAnalyzer" {
        Foreach($Rule in $AnalyzerRules) {    
            It "Should pass analyzer rule $Rule" {
                $testResults = Invoke-ScriptAnalyzer -Path $file.FullName -IncludeRule $Rule
                if ($testResults) {
                    throw ("Found {0} issues:`n{1}" -f $testResults.Count, ($testResults.Foreach{ "Line: $($_.Line) - $($_.Message) " } -join "`n"))
                }
            }
        }
    }
}