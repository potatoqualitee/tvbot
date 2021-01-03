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

######### Create directories
$dir = Split-Path -Path (Get-TvConfigValue -Name ConfigFile)

######### Create admin command files
$adminfile = Join-Path -Path $dir -ChildPath "admin-commands.json"
$userfile = Join-Path -Path $dir -ChildPath "user-commands.json"

if (-not (Test-Path -Path $adminfile)) {
    @{
        quit = 'Disconnect-TvServer -Message "k bye 👋!"'
    } | ConvertTo-Json | Set-Content -Path $adminfile -Encoding Unicode
    Set-TvConfig -AdminCommandFile $adminfile
}

######### Create user command files
if (-not (Test-Path -Path $userfile)) {
    @{
        ping = 'Write-TvChannelMessage -Message "$user, pong"'
        pwd  = 'Write-TvChannelMessage -Message $(Get-Location)'
    } | ConvertTo-Json | Set-Content -Path $userfile -Encoding Unicode
    Set-TvConfig -UserCommandFile $userfile
}

Enum ShowStates {
    Hide = 0
    Normal = 1
    Minimized = 2
    Maximized = 3
    ShowNoActivateRecentPosition = 4
    Show = 5
    MinimizeActivateNext = 6
    MinimizeNoActivate = 7
    ShowNoActivate = 8
    Restore = 9
    ShowDefault = 10
    ForceMinimize = 11
}