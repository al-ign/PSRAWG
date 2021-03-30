# where the documentation source is located
$rootdir = 'C:\Shares\personal\projects\kanboard\documentation\source\api'

# get all files
$excludeFiles = 'examples.rst','authentication.rst','index.rst','introduction.rst'
$files = gci -Path $rootdir -Filter '*.rst' -Recurse -Exclude $excludeFiles

$Descriptions =  @()

foreach ($thisFile in $files) {
    Write-Verbose $thisFile.Name

    # reading the files raw to preserve `retur`ns

    $rst = (Get-Content $thisFile.FullName -Raw)

    # regex magik
    $regex = '(?<FunctionName>\w+)[\r\n]+(?:\-{2,})[\r\n]+(?<block>[\S\s]+?)\.\.\s*code\:\:'

    # do magik
    $ss = Select-String -InputObject $rst -Pattern $regex -AllMatches

    foreach ($thisMatch in @($ss.Matches)) {
        
        # use named regex groups to fill the values
        
        $apiFunctionName = $thisMatch.Groups['FunctionName'].Value
        $f = $Functions.Where({$_.ApiFunctionName -eq $apiFunctionName})        
        $f.Doc.Filename = $thisFile.Name

        $obj = [pscustomobject]@{
            purpose = $null
            note = $null
            ressucc =$null
            resfail =$null
            blk = $null
            }

        $obj.blk = $thisMatch.Groups['block'].Value

        # not needed
        $obj.blk = $obj.blk -replace ([regex]::Escape('Request example') + '.*')
        
        # trim trailing whitespace
        $obj.blk = $obj.blk -replace '([\s])*$'

        # isn't really needed, but helps to track down issues with some lines
        $f.DOC.Source = $obj.blk
        
        # many, many regex magiks
        $regexPurpose = '(?<purp>\s*\-\s*Purpose\s*:\s*[\W\w\s]+?)(-\s*(Parameter|Result))'
        
        if ($obj.blk -match $regexPurpose) {
            $obj.purpose = $Matches.purp -replace '\n' -replace '\s{2,}',' ' -replace '\s*\-\s*Purpose:\s*' -replace '\*{2}'
            $obj.blk = $obj.blk -replace [regex]::Escape($Matches.purp)
            }

        # - Note: ...

        $regexNote = '\s*-\s*Note\s*:\s*[\W\w\s]+'

        if ($obj.blk -match $regexNote) {
            $obj.note = $Matches[0] -replace '\n' -replace '\s{2,}',' ' -replace '\s*\-\s*Note:\s*' -replace '\*{2}'
            $obj.blk = $obj.blk -replace ([regex]::Escape($Matches[0]) + '.*')
            }

        # workaround for 1 specific function
        # because nobody is doing docs the right way

        $regexNote = 'The user will only be created[\W\w\s]+'

        if ($obj.blk -match $regexNote) {
            $obj.note = $Matches[0] -replace '\n',' ' -replace '\s{2,}',' ' -replace '\s*\-\s*Note:\s*' -replace '\*{2}'
            $obj.blk = $obj.blk -replace ([regex]::Escape($Matches[0]) + '.*')
            }

        # Result on failure:

        $regexResultFail = '\s*-\s*Result\s*on\s*failure:*\s*[\*\W\w\s]+'

        if ($obj.blk -match $regexResultFail) {
            $obj.resfail = $Matches[0] -replace '\n' -replace '\s{2,}',' ' -replace '\s*-\s*Result\s*on\s*failure:*\s*' -replace '\*{2}'
            $obj.blk = $obj.blk -replace ([regex]::Escape($Matches[0]) + '.*')
            }

        # Result on success:

        $regexResultSucc = '\s*-\s*Result\s*on\s*success:*\s*[\*\W\w\s]+'

        if ($obj.blk -match $regexResultSucc) {
            $obj.ressucc = $Matches[0] -replace '\n' -replace '\s{2,}',' ' -replace '\s*-\s*Result\s*on\s*success:*\s*' -replace '\*{2}'
            $obj.blk = $obj.blk -replace ([regex]::Escape($Matches[0]) + '.*')
            }

        # Result...

        $regexResult = '\s*-\s*Result[\*\W\w\s]+'

        if ($obj.blk -match $regexResult) {
            $obj.ressucc = $Matches[0] -replace '\n' -replace '\s{2,}',' ' -replace '\s*-\s*Result:*\s*' -replace '\*{2}'
            $obj.blk = $obj.blk -replace ([regex]::Escape($Matches[0]) + '.*')
            }

        # Parameters: none

        $regexParamNone = '\s*\-\s*Parameters:\s*(\*+)*none(\*+)*[\r\n]*'

        if ($obj.blk -match $regexParamNone) {
            $obj.blk = $obj.blk -replace ([regex]::Escape($Matches[0]) + '.*')
            }

        # skip parameter extraction if the function definition doesn't have any parameters

        if ($f.params.Count -gt 0) {
            
            # - parameter [optional description] (type, required)

            $regexParam = '( *\-\s*\*{2,}(?<name>\w+)\*{2,})\s*(?<desc>\:*[\s*\w]+)*\s*(?<def>\([\w\W]+?\))'
            
            $par = Select-String -InputObject $obj.blk -Pattern $regexParam -AllMatches

            $parameters = foreach ($t in $par.Matches) {

                
                $paramObj = [pscustomobject]@{
                    value = $t.Value
                    name = $t.groups['name'].Value
                    def = $t.Groups['def'].Value -replace '^\(' -replace '\)$'  -replace '\s{2,}',' ' -replace '[\r\n]' # sigh
                    desc = $t.Groups['desc'].Value -replace '^\:\s*'
                    type = $null
                    required = $false
                    }

                switch -Regex ($paramObj.def) {
                    
                    '(\,\s*)*(required),*\s*' {
                        $paramObj.Required = $true
                        $paramObj.def = $paramObj.def -replace [regex]::Escape($Matches[0])
                        }

                    '(\,\s*)*(optional),*\s*' {
                        $paramObj.Required = $false
                        $paramObj.def = $paramObj.def -replace [regex]::Escape($Matches[0])
                        }

                    }# End switch

                # guess the parameter type
                
                switch -Regex ($paramObj.def) {

                    '^string' { 
                        $paramObj.Type = 'string'
                        $paramObj.def = $paramObj.def -replace [regex]::Escape($Matches[0])
                        }

                    '^(integer array)' {
                        $paramObj.Type = 'int[]'
                        $paramObj.def = $paramObj.def -replace [regex]::Escape($Matches[0])
                        }

                    '^(integer|int)' {
                        $paramObj.Type = 'int'
                        $paramObj.def = $paramObj.def -replace [regex]::Escape($Matches[0])
                        }

                    '^\[\]string' {
                        $paramObj.Type = 'string[]'
                        $paramObj.def = $paramObj.def -replace [regex]::Escape($Matches[0])
                        }
                    
                    '^boolean' {
                        $paramObj.Type = 'bool'
                        $paramObj.def = $paramObj.def -replace [regex]::Escape($Matches[0])
                        }

                    '^alphanumeric string' {
                        $paramObj.Type = 'string'
                        $paramObj.desc = $paramObj.desc + $_
                        $paramObj.def = $paramObj.def -replace [regex]::Escape($Matches[0])
                        }

                    } # end switch

                # if there is anything anything left in def - move it to the description

                if ($paramObj.def -match '\w.+') {
                    $paramObj.desc = $paramObj.def
                    $paramObj.def = $paramObj.def -replace [regex]::Escape($Matches[0])
                    }

                $paramObj
                }

            $f.doc.Params = $parameters

            # remove the property definition from Blk

            foreach ($p in $parameters) {
                $obj.blk = $obj.blk -replace [regex]::Escape($p.value),'!'
                }
            
            }

        # update parameter definitions with data from the documentation
        foreach ($p in $f.doc.params) {

            if ($d = $f.Params | ? Name -eq $p.name) {
                $d.Description = $p.desc
                $d.Required = $p.required
                $d.type = $p.type
                }
            }
        
        $f.DOC.Synopsis = $obj.purpose
        # regex magik. again.
        $f.DOC.Description = $f.doc.Source -replace '\*{2}'
        $f.DOC.ResultSucc = $obj.ressucc
        $f.DOC.ResultFail = $obj.resfail

        $Descriptions += $obj
        }
    }



$Functions.ps.scriptblock | Out-Null
$Functions | ? ApiFunctionName -eq createUser | tee -va z ; $z.ps.ScriptBlock; #$z.doc
