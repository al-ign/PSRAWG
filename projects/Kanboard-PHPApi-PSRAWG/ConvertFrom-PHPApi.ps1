# does what it says
filter Capitalize {
    [Regex]::Replace($_, '^\w', { param($letter) $letter.Value.ToUpper() })
    }

# where the source files are located
$rootdir = 'C:\Shares\personal\projects\kanboard\source\app\Api'

# get all files
$excludeFiles = @('BaseProcedure.php')
$files = gci -Path $rootdir -Filter '*.php' -Recurse -Exclude $excludeFiles


# create functions
$Functions = foreach ($thisFile in $files) {

    $source = (Get-Content $thisFile.FullName)

    # regex magik
    $regexFunctionDefinition = 'public\s+function\s+(?<name>\w+)\s*' + '(\((?<args>[^{]*)\))?'

    # do magik
    $ss = Select-String -InputObject $source -Pattern $regexFunctionDefinition -AllMatches
    
    foreach ($thisMatch in $ss.Matches) {
        $splat = @{
            NounPrefix = 'KB'
            ApiFunctionName = $thisMatch.Groups['name'].Value
            ApiParamsSource = $thisMatch.Groups['args'].Value -replace '\s{2,}',' '            
            ApiSource = $thisMatch.Groups[0].Value
            ApiFileName = $thisFile.Name
            }
        New-ApiObject @splat        
        }
    }

# parse and assign verbs and nouns 
foreach ($tmp in $Functions) {
            # Make PS Verb-Noun pairs
        switch -Regex ($tmp.ApiFunctionName) {
            '^get(.+)$' {
                $tmp.Verb = 'Get'
                $tmp.Noun = $Matches[1]
                }
            
            '^remove(.+)$' {
                $tmp.Verb = 'Remove'
                $tmp.Noun = $Matches[1]
                }
            
            '^create(.+)$' {
                $tmp.Verb = 'New'
                $tmp.Noun = $Matches[1]
                }
            
            '^update(.+)$' {
                $tmp.Verb = 'Set'
                $tmp.Noun = $Matches[1]
                }
            
            '^enable(.+)$' {
                $tmp.Verb = 'Enable'
                $tmp.Noun = $Matches[1]
                }
            
            '^disable(.+)$' {
                $tmp.Verb = 'Disable'
                $tmp.Noun = $Matches[1]
                }
            
            '^add(.+)$' {
                $tmp.Verb = 'Add'
                $tmp.Noun = $Matches[1]
                }
            
            '^close(.+)$' {
                $tmp.Verb = 'Close'
                $tmp.Noun = $Matches[1]
                }
            
            '^set(.+)$' {
                $tmp.Verb = 'Set'
                $tmp.Noun = $Matches[1]
                }

            '^move(.+)$' {
                $tmp.Verb = 'Move'
                $tmp.Noun = $Matches[1]
                }
            
            '^change(.+)$' {
                $tmp.Verb = 'Set'
                $tmp.Noun = $Matches[1]
                }

            '^save(.+)$' {
                $tmp.Verb = 'Set'
                $tmp.Noun = $Matches[1]
                }

            # Function Specific - should be run after all other replacements

            '^(open|close)(Task)$' {
                $tmp.Verb = $Matches[1] | Capitalize
                $tmp.Noun = $Matches[2]
                $tmp.FriendlyAlias = '{0}-{2}{1}' -f 'Set', ('TaskStatus' + ($Matches[1] | Capitalize)), $tmp.PS.NounPrefix
                }
            
            '^duplicateTaskToProject$' {
                $tmp.Verb = 'Copy'
                $tmp.Noun = 'TaskToProject'
                $tmp.FriendlyAlias = '{0}-{2}{1}' -f 'Duplicate', 'TaskToProject', $tmp.PS.NounPrefix
                }
            
            '^searchTasks$' {
                $tmp.Verb = 'Find'
                $tmp.Noun = 'Tasks'
                $tmp.FriendlyAlias = '{0}-{2}{1}' -f 'Get', 'Tasks', $tmp.PS.NounPrefix
                }

            '^moveTaskPosition$' {
                $tmp.Verb = 'Set'
                $tmp.Noun = 'TaskPosition'
                $tmp.FriendlyAlias =  '{0}-{2}{1}' -f 'Move', 'TaskPosition', $tmp.PS.NounPrefix
                }

            '^downloadTaskFile$' {
                $tmp.Verb = 'Invoke'
                $tmp.Noun = 'downloadTaskFile'
                $tmp.FriendlyAlias = '{0}-{2}{1}' -f 'Get', 'TaskFileDownload', $tmp.PS.NounPrefix
                }

            '^downloadProjectFile$' {
                $tmp.Verb = 'Invoke'
                $tmp.Noun = 'downloadProjectFile'
                $tmp.FriendlyAlias = '{0}-{2}{1}' -f 'Get', 'ProjectFileDownload', $tmp.PS.NounPrefix
                }

            # default

            default {
                $tmp.Verb = 'Invoke'
                $tmp.Noun = $tmp.ApiFunctionName
                }
                
            } # end switch
    
    }



# parse and create parameters
foreach ($tmp in $Functions) {

     # find out how many argumetns are there
        $argumentCount = Select-String -InputObject $tmp.Api.ParamsSource -Pattern '\$' -AllMatches
        
        if ($argumentCount.Matches.Count -eq 1) {
            $tmp.Api.Params = @( $tmp.Api.ParamsSource -replace '^\(' -replace '\)$' )
            }

        if ($argumentCount.Matches.Count -ge 2) {
            $tmp.Api.Params = @( $tmp.Api.ParamsSource  -replace '^\(' -replace '\)$' -split '\s*\,\s*' )
            }

        # another regex magik
        if ($tmp.Api.Params.Count -gt 0) {
            foreach ($thisArg in $tmp.Api.Params) {
                
                if ($thisArg -Match '^(?<type>.+\s+)?(?<var>\$.+)\s*=\s*(?<val>.+)$') {
                    
                    $splat = @{
                        Name = $Matches.Var -replace '^\$' -replace '\s' -replace '^array\$'
                        UsedIn = 'json'
                        }
                    $tmp.Params += New-ApiParam @splat

                    }
                elseif ($thisArg -match '^(?<var>.+)\s*$') {
                    $splat = @{
                        Name = $Matches.Var -replace '^\$' -replace '\s' -replace '^array\$'
                        UsedIn = 'json'
                        }
                    $tmp.Params += New-ApiParam @splat
                    }
                }
            }
    }
     