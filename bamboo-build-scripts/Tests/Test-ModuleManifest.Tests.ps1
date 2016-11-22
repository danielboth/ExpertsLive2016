param (
    $ModuleName = '*'
)

foreach ($manifest in Get-ChildItem .\$ModuleName\$ModuleName.psd1) {
    if ($manifest.Basename -ne $manifest.Directory.Name) {
        continue
    }
    Describe "Testing Module Manifest Metadata: $($manifest.BaseName)" {
        It 'Has proper manifest' {
            { Test-ModuleManifest -Path $manifest.FullName } | Should not throw
        }
        Context "Testing properties within module manifest $($manifest.BaseName)" {
            $moduleInfo = Test-ModuleManifest -Path $manifest.FullName -ErrorAction SilentlyContinue
            It 'Has author defined' {
                $moduleInfo.Author | Should not BeNullOrEmpty
            }
            It 'Has description defined' {
                $moduleInfo.Description | Should not BeNullOrEmpty
            }
            It 'Has tags in PSData' {
        
                $moduleInfo.PrivateData.PSData.Tags | Should not BeNullOrEmpty
            }
            It 'Has Project URI' {
                $moduleInfo.PrivateData.PSData.ProjectUri | Should not BeNullOrEmpty
            }
            It 'Project URI Points to BitBucket' {
                $moduleInfo.PrivateData.PSData.ProjectUri | Should Match ([regex]::Escape('http://bitbucket.expertslive.local'))
            }
            It 'Has a version with 4 digits' {
                $moduleInfo.Version.ToString().Split('.').Count | Should be 4
            }

            It 'Has Company configured' {
                $moduleInfo.CompanyName | Should Not BeNullOrEmpty
            }

            if ($moduleInfo.RootModule) {
                $modulePath = $manifest.FullName | Split-Path -Parent 
                $fullPath = Join-Path -ChildPath $moduleInfo.RootModule -Path $modulePath

                $ast = [System.Management.Automation.Language.Parser]::ParseFile($fullPath, [ref]$null, [ref]$null)
                $astFunctionSearch =  { 
                    $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
                }

                $functionNames = $ast.FindAll(
                    $astFunctionSearch,
                    $false
                ) | Where-Object Name -Like *-OP* | ForEach-Object Name
                if (-not $functionNames) {
                    # Using 'dot-source' model, lets verify it...
                    $dotSourcing = $ast.FindAll(
                        { 
                            $args[0] -is [System.Management.Automation.Language.CommandAst] -and 
                            $args[0].InvocationOperator -eq [System.Management.Automation.Language.TokenKind]::Dot 
                        }, 
                        $false
                    )
                    if ($dotSourcing) {
                        # For now - I assume 'our' model - dot-source all ps1's in current folder...
                        $functionNames = @()
                        foreach ($script in Get-ChildItem -Path "$modulePath\*.ps1") {
                            $scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$null)
                            $functions = $scriptAst.FindAll(
                                $astFunctionSearch,
                                $false
                            )
                            $functionNames += $functions | Where-Object Name -Like *-OP* | ForEach-Object Name
                            # Quick test on ps1's to verify we are not doing anything odd...
                            It "Should contain just one function definition in $($script.Name)" {
                                $functions.Count | Should be 1
                            }
                            It "Function name should be same as file name $($script.Basename)" {
                                $functions.Name | Should be $script.Basename
                            }
                            It "Function defined in $($script.Name) should not be called" {
                                $scriptAst.FindAll(
                                    {
                                        $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                                        $args[0].CommandElements[0].Value -eq $script.Basename
                                    },
                                    $false
                                ) | Should BeNullOrEmpty
                            }
                        }
                    }
                }
                $exportedFunctions = $moduleInfo.ExportedFunctions.Keys

                foreach ($name in $functionNames) {

                    It "Exports exports function $name in manifest" {

                        if ([System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters($exportedFunctions)) {
                            $name -like $exportedFunctions | Should be $true

                        } else {
                            $exportedFunctions -contains $name | Should be $true
                        }
                    }
                }    
            }
        }
    }
}

