function Get-TvUser {
    <#
    .SYNOPSIS
        Gets Twitch User
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$UserName
    )
    process {
        if (-not $PSBoundParameters.UserName) {
            Invoke-TvRequest -Path /users
        } else {
            $users = $UserName -join "&login="
            Invoke-TvRequest -Path /users?login=$users
        }
    }
}