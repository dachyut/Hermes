##################
### Build Datacastle/Citadel/MidmarketEndpoint
###
### To refine the build, add one of the below environment variables to your command line
### Variables are commented out for now and would need to investigate the usage.
##################
Param (
	[parameter(Mandatory=$true, HelpMessage="Usually FAST or NIGHTLY")] [string] [ValidateSet("FAST","NIGHTLY")] $BuildType,
	[parameter(Mandatory=$true, HelpMessage="Usually NightlyLite or NightlyFull")] [string]  [ValidateSet("NightlyLite","NightlyFull")] $TFSBuildType,
	[parameter(Mandatory=$true, HelpMessage="IP or FQHN of a Mac build machien to control")] [string]  $MacBuild,
	[parameter(Mandatory=$true, HelpMessage="Credentials for the Mac Build Machine")] [string]  $MacBuildUsername,
	[parameter(Mandatory=$true, HelpMessage="Credentials for the Mac Build Machine")] [string]  $MacBuildPassword,
	[parameter(HelpMessage="Index of the brand being built")] [int] $BuildBrandIndex = 0,
	[parameter(HelpMessage="Defaults to 1 to obfuscate, else specify 0 to NOT")] [bool] $ObfuscateServer = $true,
	[parameter(HelpMessage="Defaults to 1 to skip obfuscating the client, else specify 0 to do so")] [bool] $SkipClientObfuscation = $true,
	[parameter(HelpMessage="CSV for skipping components")] [string []] $SkipComponents = "",
    [parameter(HelpMessage="RC, Nightly, CI or PR")] [string] [ValidateSet("RC","Nightly","CI","PR")] $BuildLevel = ""
)

###
# set DoNotIncludeQuickCache=true DoNotIncludeResetServer=true DoNotIncludeTools=true
# set SkipClientObfuscation=true
# set SkipCodeSigning=true
# set DoNotBuildClients=true
###

Write-Output "BUILDLEVEL: $($BuildLevel)"

[String []]$OptionalArgs = @()
if ($SkipComponents.Contains("skipServerObfuscation") -and $BuildLevel -eq "PR") {
    Write-Output "SKIPPING SERVER OBFUSCATION"
    $OptionalArgs += "DoNotObfusateVault=true"
    $OptionalArgs += "DoNotObfuscateQuickCache=true"
    $OptionalArgs += "DoNotObfuscateTools=true"
    $OptionalArgs += "DoNotObfuscateResetServer=true"
}

if ($SkipComponents.Contains("skipClientObfuscation") -and $BuildLevel -eq "PR") {
    Write-Output "SKIPPING CLIENT OBFUSCATION"
    $OptionalArgs += "SkipClientObfuscation=true"
}

Write-Output $SkipComponents

if ($SkipComponents.Contains("skipLDAPSync") -and $BuildLevel -eq "PR") {
    Write-Output "SKIPPING LDAP SYNC"
    $OptionalArgs += "DoNotIncludeLDAPSync=true"
}

if ($SkipComponents.Contains("skipQuickCache") -and $BuildLevel -eq "PR") {
    Write-Output "SKIPPING Quick Cache"
    $OptionalArgs += "DoNotIncludeQuickCache=true"
}

if ($SkipComponents.Contains("skipTools") -and $BuildLevel -eq "PR") {
    Write-Output "SKIPPING TOOLS"
    $OptionalArgs += "DoNotIncludeTools=true"
}

if ($SkipComponents.Contains("skipSigning") -and $BuildLevel -eq "PR") {
    Write-Output "SKIPPING SIGNING"
    $OptionalArgs += "DoNotIncludeSigning=true"
}

if ($SkipComponents.Contains("skipSQLExpress") -and $BuildLevel -eq "PR") {
    Write-Output "SKIPPING Vault Bootstrapper (branded and non-branded) SQL express"
    $OptionalArgs += "DoNotIncludeSQLExpress=true"
}

if ($SkipComponents.Contains("skipMacClient") -and $BuildLevel -eq "PR") {
    Write-Output "SKIPPING Mac Client Build"
    $OptionalArgs += "DoNotIncludeMacClient=true"
    $RemoteResources = "artifacts.carb.lab"
} else {
    $RemoteResources = "artifacts.carb.lab", $MacBuild
}

if ($SkipComponents.Contains("skipResetServer") -and $BuildLevel -eq "PR") {
    Write-Output "SKIPPING Reset Server"
    $OptionalArgs += "DoNotIncludeResetServer=true"
}

$working_directory= $ENV:WORKSPACE

$cmd = "C:\program files\VisBuildPro9\visbuildcmd.exe"
$buildFile = "{0}\build\datacastle.bld" -f $working_directory
$logFile = """{0}\Build.log""" -f $working_directory

"Prior to running build, verify connection to " + $RemoteResources


Write-Output $cmd $buildFile WORKING_DIRECTORY=$working_directory MACBUILD=$MacBuild MACBUILD_USER=$MacBuildUsername MACBUILD_PWD=$MacBuildPassword BUILD_TYPE=$BuildType TFSBUILDTYPE=$TFSBuildType OUTPUTSUBDIR=$BuildBrandIndex RUN_UNIT_TESTS_OBFUSCATED=false RUN_UNIT_TESTS=true TEST_TYPE=Minimum BUILD_BRAND_INDEX=$BuildBrandIndex @OptionalArgs /logfile $logFile /nologo /nooutput
& $cmd $buildFile WORKING_DIRECTORY=$working_directory MACBUILD=$MacBuild MACBUILD_USER=$MacBuildUsername MACBUILD_PWD=$MacBuildPassword BUILD_TYPE=$BuildType TFSBUILDTYPE=$TFSBuildType OUTPUTSUBDIR=$BuildBrandIndex RUN_UNIT_TESTS_OBFUSCATED=false RUN_UNIT_TESTS=true TEST_TYPE=Minimum BUILD_BRAND_INDEX=$BuildBrandIndex @OptionalArgs /logfile $logFile /nologo /nooutput
If ($LastExitCode -ne 0) {Exit 1}

### Collect build properties and generate a properties file
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\generate_build_properties.ps1"
