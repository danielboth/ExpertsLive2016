$registerSplat = @{
    Name = 'Artifactory'
    SourceLocation = 'http://artifactory:8081/artifactory/api/nuget/powershell-gallery'
    PublishLocation = 'http://artifactory:8081/artifactory/api/nuget/powershell-gallery'
    InstallationPolicy = 'Trusted'
}

Register-PSRepository @registerSplat