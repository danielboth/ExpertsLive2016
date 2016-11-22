Show-Logo -Logo WhatIsGit -Width 1000 -Opacity 1

$ModuleName = 'ExpertsModule'
$Destination = "C:\expertslive\Demo2 - First attempt on a module\$ModuleName"

Push-Location $Destination

# Create repository locally
git init

# Commit initial changes
git add --all
git commit -m "Initial Commit"

# Upload to bitbucket repository
git remote add origin http://expert@bitbucket.expertslive.local:7990/scm/el/demo2.git
git push -u origin master