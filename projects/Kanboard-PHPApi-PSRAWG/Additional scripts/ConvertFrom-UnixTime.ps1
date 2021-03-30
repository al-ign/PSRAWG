<#
.Synopsis
   Convert input seconds from unixtime to the local time
.DESCRIPTION
   Convert input seconds from unixtime to the local time
.EXAMPLE
   43235345 | ConvertFrom-UnixTime
.EXAMPLE
   ConvertFrom-UnixTime 1233545
#>
function ConvertFrom-UnixTime {
    [CmdletBinding()]
    [OutputType([datetime])]
    Param (
        # Unixtime
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]$Unixtime
        )
    
    Process {
        [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Unixtime))
        }
    
    }