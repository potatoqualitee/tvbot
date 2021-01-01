function Get-TvSystemTheme {
    <#
    .SYNOPSIS
        Connects to a Twitch

    .DESCRIPTION
        Connects to a Twitch

    .EXAMPLE
        PS C:\>

#>
    [CmdletBinding()]
    param ()
    process {
        $reg = Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize

        if ($reg.SystemUsesLightTheme) {
            $theme = "light"
            $color = "white"
        } else {
            $theme = "dark"
            $color = "black"
        }

        if ($configcolor = Get-TvConfigValue -Name NotifyColor) {
            $color = $configcolor
        }

        [pscustomobject]@{
            Theme = $theme
            Color = $color
        }
    }
}