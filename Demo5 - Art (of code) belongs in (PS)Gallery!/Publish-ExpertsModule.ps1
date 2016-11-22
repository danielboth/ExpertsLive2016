$nugetApiKey = 'expert:AP56KgC9AbZUGM9gSiXKxMK6Dn3'

Find-Module -Repository Artifactory


# Publish module to gallery
Publish-Module -Path 'C:\expertslive\Demo4 - The more (files) the merrier\ExpertsModule' -Repository Artifactory -NuGetApiKey $nugetApiKey

# Find / Get-Installed / Install / Update