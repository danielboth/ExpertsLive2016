$nugetApiKey = 'expert:AP56KgC9AbZUGM9gSiXKxMK6Dn3'

# First copy module to PowerShell modules folder
Copy-Item 'C:\expertslive\Demo4 - The more (files) the merrier\ExpertsModule' -Destination 'C:\Program Files\WindowsPowerShell\Modules' -Recurse

Publish-Module -Name ExpertsModule -Repository Artifactory -NuGetApiKey $nugetApiKey