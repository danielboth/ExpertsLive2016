# Script used by Bamboo agents

This repo is the one that is used by all OS Bamboo plans to run PowerShell code.

Description of scripts:

|Name|Description|
|:---:|---|
|Publish-LcmConfiguration.ps1|Generate meta.mof documents in selected location based on ConfigurationData.psd1 for individual nodes.|
|Publish-PartialConfiguration.ps1|Generate PartialConfiguration.mof documents on the Pull Server based on PartialConfiguration.ps1 files.|
|Start-ModuleUpdate.ps1|Publish modules/ DSC resources to our internall PowerShell gallery.|
|Start-PesterTest.ps1|Tests scripts/modules with some general tests and tests in individual tests. For general folder *Tests* is used. For local *PesterTests* within given repo is used.|
|Update-BambooModule.ps1|Update module(s) on Bamboo agent.|
|Update-DscResourceModule.ps1|Update DSC resources on Bamboo agent and Pull Server (zip)|
