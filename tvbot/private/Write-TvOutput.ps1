function Write-TvOutput {
    <#
    .SYNOPSIS
        This command parses output from the server and writes it to console

    .DESCRIPTION
        This command parses output from the server and writes it to console

    .PARAMETER InputObject
        The data from the server

    .PARAMETER Channel
        The channel to post to

    .PARAMETER Owner
        The admins of the bot

    .EXAMPLE
        PS> Wait-TvInput
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory)]
        [string]$InputObject,
        [string]$Channel = $script:Channel,
        [string[]]$Owner = $script:Owner,
        [ValidateSet("chat", "leave", "join")]
        [string[]]$Notify
    )
    process {
        if (-not $writer.BaseStream) {
            Write-Error -ErrorAction Stop -Message "Have you connected to a server using Connect-TvServer?"
        }

        $irctagregex = [Regex]::new('^(?:@([^ ]+) )?(?:[:]((?:(\w+)!)?\S+) )?(\S+)(?: (?!:)(.+?))?(?: [:](.+))?$')
        $match = $irctagregex.Match($InputObject) #tags = 1
        $prefix = $match.Groups[2].Value
        $user = $match.Groups[3].Value
        $command = $match.Groups[4].Value
        $params = $match.Groups[5].Value
        $message = $match.Groups[6].Value

        $hash = @{}
        # Thanks mr mark!
        $InputObject.split(';') | ForEach-Object {
            $split = $PSItem.Split('=')
            $key = $split[0]
            $value = $split[1]
            if (-not $hash[$key]) {
                $hash.Add($key,$value)
            }
        }
        $displayname = $hash["display-name"]
        $emote = $hash["emotes"]
        $emoteonly = [bool]$hash["emote-only"]

        Write-Verbose $InputObject
        # format it
        switch ($command) {
            "USERNOTICE" {
                $user = $displayname
                $sysmsg = $hash["system-msg"]
                if ($sysmsg -match "raiders") {
                    $image = Get-Avatar

                    # 15\sraiders\sfrom\sTdanni_juhl\shave\sjoined\n!
                    $text = $sysmsg.Replace("\s"," ").Replace("\n","")
                    $appicon = New-BTImage -Source (Get-TvConfigValue -Name RaidIcon) -AppLogoOverride

                    $heroimage = New-BTImage -Source (Get-TvConfigValue -Name RaidImage) -HeroImage

                    $titletext = New-BTText -Text "$displayname $(Get-TvConfigValue -Name RaidText)"
                    $thankstext = New-BTText -Text $text

                    $audio = New-BTAudio -Source (Get-TvConfigValue -Name RaidSound)

                    $binding = New-BTBinding -Children $titletext, $thankstext -HeroImage $heroimage -AppLogoOverride $appicon
                    $visual = New-BTVisual -BindingGeneric $binding
                    $content = New-BTContent -Visual $visual -Audio $audio
                    Submit-BTNotification -Content $content -UniqueIdentifier $id
                }
            }
            "PRIVMSG" {
                if ($message) {
                    if ($user) {
                        Write-Verbose "Display name: $displayname"
                        Write-Output "[$(Get-Date)] <$user> $message"

                        if ($Notify -contains "chat" -and $user -notin (Get-TvConfigValue -Name BotsToIgnore)) {
                            if ($message) {
                                try {
                                    # THANK YOU @vexx32!
                                    $string = ($message -replace '\x01').Replace("ACTION ", "")
                                    $id = "tvbot"
                                    $image = (Resolve-Path "$script:ModuleRoot\icon.png")

                                    if ($script:toast) {
                                        $image = Get-Avatar

                                        Write-Verbose "EMOTE: $emote"
                                        Write-Verbose "EMOTE ONLY: $emoteonly"

                                        if ($emote) {
                                            $emote, $location = $emote.Split(":")

                                            if (-not $emoteonly) {
                                                $location = $location.Split(",")
                                                Write-Verbose "$location"
                                                foreach ($match in $location) {
                                                    $first, $last = $match.Split("-")
                                                    # Thanks milb0!
                                                    $remove = $message.Substring($first, $last - $first + 1)
                                                    $string = $message.Replace($remove, "")
                                                }
                                            }

                                            $image = Get-TvEmote -Id $emote
                                        }

                                        $existingtoast = Get-BTHistory -UniqueIdentifier $id
                                        if ($existingtoast) {
                                            Remove-BTNotification -Tag $id -Group $id
                                        }

                                        $bigolbits = [int]$hash["bits"]

                                        if ($bigolbits -gt 0) {
                                            if ($bigolbits -eq 1) {
                                                $bitword = "BIT"
                                            } else {
                                                $bitword = "BITS"
                                            }
                                            $appicon = New-BTImage -Source (Get-TvConfigValue -Name BitsIcon) -AppLogoOverride
                                            $heroimage = New-BTImage -Source (Get-TvConfigValue -Name BitsImage) -HeroImage

                                            $titletext = New-BTText -Text (Get-TvConfigValue -Name BitsTitle)
                                            $thankstext = New-BTText -Text "$(Get-TvConfigValue -Name BitsText) $bigolbits $bitword, $displayname!"

                                            $audio = New-BTAudio -Source (Get-TvConfigValue -Name BitsSound)

                                            $binding = New-BTBinding -Children $titletext, $thankstext -HeroImage $heroimage -AppLogoOverride $appicon
                                            $visual = New-BTVisual -BindingGeneric $binding
                                            $content = New-BTContent -Visual $visual -Audio $audio

                                            Submit-BTNotification -Content $content -UniqueIdentifier $id
                                            # parse out if they said more than just the bit so that you can show that
                                        } else {
                                            try {
                                                New-BurntToastNotification -AppLogo $image -Text $displayname, $string -UniqueIdentifier $id -ErrorAction Stop
                                            } catch {

                                            }
                                        }
                                    } else {
                                        $string = [System.Security.SecurityElement]::Escape($message)
                                        Send-OSNotification -Title $user -Body $string -Icon $image -ErrorAction Stop
                                    }
                                } catch {
                                    $_
                                }
                            }
                        }
                    } else {
                        Write-Output "[$(Get-Date)] > $message"
                    }
                    if (-not $Notify -or $message -eq "!quit") {
                        Invoke-TvCommand -InputObject $message -Channel $script:Channel -Owner $Owner -User $user
                    }
                }
            }
            "JOIN" {
                Write-Output "[$(Get-Date)] *** $user has joined #$script:Channel"

                if ($Notify -contains "join") {
                    Send-OSNotification -Title $user -Body "$user has joined" -Icon (Resolve-Path "$script:ModuleRoot\icon.png")
                }
            }
            "PART" {
                Write-Output "[$(Get-Date)] *** $user has left #$script:Channel"

                if ($Notify -contains "leave") {
                    Send-OSNotification -Title $user -Body "$user has has left" -Icon (Resolve-Path "$script:ModuleRoot\icon.png")
                }
            }
            "PING" {
                $script:ping = [DateTime]::Now
                Send-Server -Message "PONG"
            }
            353 {
                $members = $message.Split(" ")
                if ($members.Count -le 100) {
                    Write-Output "[$(Get-Date)] > Current user list:"
                    foreach ($member in $members) {
                        Write-Output "  $member"
                    }
                } else {
                    Write-Verbose "[$(Get-Date)] > Current user list:"
                    foreach ($member in $members) {
                        Write-Verbose "  $member"
                    }
                }
            }
            { $psitem.Trim() -in 001, 002, 003, 372 } {
                Write-Output "[$(Get-Date)] > $message"
            }
            default {
                Write-Verbose "[$(Get-Date)] command: $command"
                Write-Verbose "[$(Get-Date)] message: $message"
                Write-Verbose "[$(Get-Date)] params: $params"
                Write-Verbose "[$(Get-Date)] prefix: $prefix"
                Write-Verbose "[$(Get-Date)] user: $user"
            }
        }
    }
}