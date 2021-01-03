﻿$script:ModuleRoot = $PSScriptRoot

function Import-ModuleFile {
    [CmdletBinding()]
    Param (
        [string]
        $Path
    )

    if ($doDotSource) { . $Path }
    else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($Path))), $null, $null) }
}

# Detect whether at some level dotsourcing was enforced
if ($tvbot_dotsourcemodule) { $script:doDotSource }

# Import all internal functions
foreach ($function in (Get-ChildItem "$ModuleRoot\private\" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $function.FullName
}

# Import all public functions
foreach ($function in (Get-ChildItem "$ModuleRoot\public" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $function.FullName
}

if (Get-Command -Name New-BurntToastNotification -Module BurntToast -ErrorAction SilentlyContinue) {
    # sqlite shared cache
    $script:toast = $true
    $script:cache = @{}
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($PSVersionTable.Platform -ne "UNIX") {
    Add-Type -AssemblyName PresentationFramework, System.Windows.Forms
}

##################### Config setup #####################
$config = Get-TvConfig
$dir = Split-Path -Path $config.ConfigFile
$params = @{}

if (-not $config.RaidIcon) {
    if (-not (Test-Path -Path "$dir\pog.png")) {
        Copy-Item "$script:ModuleRoot\images\pog.png" -Destination "$dir\pog.png"
    }
    $params.RaidIcon = "$dir\pog.png"
}
if (-not $config.RaidImage) {
    if (-not (Test-Path -Path "$dir\catparty.gif")) {
        Copy-Item "$script:ModuleRoot\images\catparty.gif" -Destination "$dir\catparty.gif"
    }
    $params.RaidImage = "$dir\catparty.gif"
}
if (-not $config.BitsIcon) {
    if (-not (Test-Path -Path "$dir\bits.gif")) {
        Copy-Item "$script:ModuleRoot\images\bits.gif" -Destination "$dir\bits.gif"
    }
    $params.BitsIcon = "$dir\bits.gif"
}
if (-not $config.BitsImage) {
    if (-not (Test-Path -Path "$dir\vibecat.gif")) {
        Copy-Item "$script:ModuleRoot\images\vibecat.gif" -Destination "$dir\vibecat.gif"
    }
    $params.BitsImage = "$dir\vibecat.gif"
}

if (-not $config.BotIcon) {
    if (-not (Test-Path -Path "$dir\robo.png")) {
        Copy-Item "$script:ModuleRoot\images\robo.png" -Destination "$dir\robo.png"
    }
    $params.BotIcon = "$dir\robo.png"
}

if ($config.NotifyType -eq "none") {
    $params.NotifyType = "chat"
}
$null = Set-TvConfig @params