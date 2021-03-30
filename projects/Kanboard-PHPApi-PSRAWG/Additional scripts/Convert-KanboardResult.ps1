<#
.Synopsis
   Convert Kanboard API request to .NET types
.DESCRIPTION
   Convert the values of Kanboard API response to the more usable .NET/PS types
.EXAMPLE
   $res.result | Convert-KanboardResult
#>
function Convert-KanboardResult {
    [CmdletBinding()]
    [Alias()]
    Param (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        $Data,
        [switch]$PassThru
    )

    foreach ($obj in $Data) {
        $gm = Get-Member -MemberType NoteProperty -InputObject $obj
        
        foreach ($np in $gm) {

            # Convert datetime to .NET type
            if ($np.Name -match '^(date_|last_modified)') {
                
                if ($obj.$($np.Name) -gt 0) {

                    try {
                        $obj.$($np.Name) = ConvertFrom-UnixTime $($obj.$($np.Name) )
                        }
                    catch {
                        Write-Warning ('Failed to convert property "{0}" with value "{1}" to the datetime' -f $np.Name, $obj.$($np.Name))
                        }
                    
                    }
                
                }

            }
        }

    if ($PassThru) {
        $Data
        }

    } # End Convert-KanboardResult function


