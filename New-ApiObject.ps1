function New-ApiObject {
param (
    # Prefix to add to the nouns aka module prefix
    $NounPrefix = '',
    $ApiFunctionName,
    $Verb,
    $Noun,
    $ApiFilename,
    $ApiSource,
    $ApiParamsSource
    )

    $obj = [pscustomobject]@{

        # as in API we are parsing
        ApiFunctionName = $ApiFunctionName

        # PS
        Verb = $Verb
        Noun = $Noun

        # a more discoverable (in PS terms) alias
        FriendlyAlias = $null

        # 
        SyntaxCheckPass = $false
        SyntaxCheckError = $null

        
        Params = @()

            
        DOC = [pscustomobject]@{
            Synopsis = $null
            Description = $null
            Params = $null
            ResultSucc = $null
            ResultFail = $null
            Blk = $null
            Source = $null
            FileName = $null
            Parent = $null
            }


        API = [pscustomobject]@{
            #
            Params = @()
            
            #
            ParamsSource = $ApiParamsSource
            
            # API source as-is
            Source = $ApiSource

            # API filename what were parsed
            FileName = $ApiFilename
            
            # placeholder for the parent object
            Parent = $null
            }
        
        PS = [pscustomobject]@{
            #
            NounPrefix = $NounPrefix
            
            #DefaultParameterSetName
            DefaultParameterSetName = $null

            BeginBlock = @()
            ProcessBlock = @()
            EndBlock = @()

            # placeholder for the parent object
            Parent = $null
            }

        #Commented out because I don't need them, but they could be useful if there is a complex directory structure
        #RelativeName = $thisFile.FullName -replace [regex]::Escape($rootdir)
        #FullName = $thisFile.FullName
        }

    # Abomination
    $obj.PS.parent = $obj
    $obj.API.parent = $obj
    $obj.DOC.parent = $obj

    # make a 'safe' alias with API function name
    $SafeAlias = {
        
        # inline declaration just to be safe
        filter Capitalize {
            [Regex]::Replace($_, '^\w', { param($letter) $letter.Value.ToUpper() })
            }
        
        'Invoke-{1}{0}' -f ($this.Parent.ApiFunctionName | Capitalize), $this.NounPrefix
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'SafeAlias'
        Value = $SafeAlias
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam -Verbose

    ###

    # return non $null aliases
    $Aliases = {
        @($this.SafeAlias, $this.parent.FriendlyAlias | ? {$null -ne $_} ) 
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'Aliases'
        Value = $Aliases
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam 

    ###

    # auto make PS function name
    $sbPSFunctionName = {
        '{0}-{2}{1}' -f $this.Verb, $this.Noun, $this.PS.NounPrefix
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'PSFunctionName'
        Value = $sbPSFunctionName
        Force = $true
        }
    Add-Member -InputObject $obj @memberParam 
    
    ###

    # auto make PS Parameter Block
    $ParameterBlock = {
        $arrStr = @()
        $arrStr += 'Param ('

        $joinedParams = foreach ($thisParam in $this.parent.Params) {
            $thisParam.PSParameter -join [environment]::NewLine
            }

        # moar string manipulation magik
        $arrStr += $joinedParams -join (',{0}{0}' -f [environment]::NewLine) -split [environment]::NewLine

        $arrStr += '    )'
        $arrStr
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'ParameterBlock'
        Value = $ParameterBlock
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam 

    ###

    # auto make PS help block
    $HelpBlock = {

        # try to format the help block with the weird PS 3 spaces notation
        filter Prepend3Spaces {
            $x = $_
            (($x -split '[\n\r]+') | % {$_ -replace '(^.)','   $1'}) -join [System.Environment]::NewLine
            }

        $arrStr = @()

        $arrStr += '<#'
        $arrStr += '.Synopsis'

        if ($this.parent.Doc.Synopsis) {
            $arrStr += '{0}' -f $this.parent.Doc.Synopsis | Prepend3Spaces
            }
        else {
            $arrStr += '   Invoke {0}' -f $this.parent.ApiFunctionName
            }

        $arrStr += '.DESCRIPTION'

        if ($this.parent.Doc.Description) {
            $arrStr += '{0}' -f $this.parent.Doc.Description | Prepend3Spaces
            }
        else {
            $arrStr += '   Invoke {0}' -f $this.parent.ApiFunctionName
            }
        
        if ($this.Aliases) {
            $arrStr += '   Alias: {0}' -f ($this.Aliases -join ', ')
            }

        if ($this.parent.Doc.ResultSucc -or $this.parent.Doc.ResultFail) {

            $arrStr += '.OUTPUTS'

            if ($this.parent.Doc.ResultSucc) {
               $arrStr += '   Returns {0} on success' -f $this.parent.Doc.ResultSucc
               }

            if ($this.parent.Doc.ResultFail) {
               $arrStr += '   Returns {0} on failure' -f $this.parent.Doc.ResultFail
               }

            }

        $arrStr += '.NOTES'
        $arrStr += '   API Function Name: {0}' -f $this.parent.ApiFunctionName
        $arrStr += '   PS Module Safe Name: {0}' -f $this.parent.ps.SafeAlias

        if ($this.parent.API.Filename) {
            $arrStr += '   Function parsed from: {0}' -f $this.parent.API.Filename
            }

        if ($this.parent.Doc.FileName) {
            $arrStr += '   Description parsed from: {0}' -f $this.parent.Doc.FileName
            }

        $arrStr += '#>'

        $arrStr

        } # END auto make ps help block

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'HelpBlock'
        Value = $HelpBlock
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam 

    ###

    # auto make PS Header block
    $HeaderBlock = {
        $arrStr = @()
        
        $arrStr += "function {0} {{" -f $this.parent.PSFunctionName
        
        if ($this.DefaultParameterSetName) {
            $arrStr += "[CmdletBinding(DefaultParameterSetName='{0}')]" -f $this.DefaultParameterSetName
            }
        else {
            $arrStr += '[CmdletBinding()]'
            }

        if ($this.parent.PS.Aliases) {
            $arrStr += "[Alias('{0}')]"  -f ($this.parent.PS.Aliases -join "', '")  
            }
        
        $arrStr
        } #end header block

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'HeaderBlock'
        Value = $HeaderBlock
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam 
    
    ###

    # auto make PS function footer
    $FooterBlock = {
        ''
        '}} # End {0} function' -f $thisFunction.PSFunctionName
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'FooterBlock'
        Value = $FooterBlock
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam 

    ###
    
    # Compose the main function block

    $MainBlock = {
        $arrStr = @()
        
#        if ($this.BeginBlock) {
            $arrStr += 'Begin {'

            #add some helper functions, comment next line if you don't need them
            $this.HelperFunctionsBlock -split [environment]::NewLine | % {$arrStr += $_}

            $this.BeginBlock -split [environment]::NewLine | % {$arrStr += $_}
            $arrStr += '} # End begin block'
            $arrStr += ''
 #           }

        if ($this.ProcessBlock) {
            $arrStr += 'Process {'
            $this.ProcessBlock -split [environment]::NewLine | % {$arrStr += $_}
            $arrStr += '} # End process block'
            $arrStr += ''
            }

        if ($this.EndBlock) {
            $arrStr += 'End {'
            $this.EndBlock -split [environment]::NewLine | % {$arrStr += $_}
            $arrStr += '} # End end block'
            $arrStr += ''
            }

        $arrStr
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'MainBlock'
        Value = $MainBlock
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam 
    
    ###

    # Compile all blocks into the one
    $FunctionText = {
        $sb = [System.Text.StringBuilder]::new()
    
        filter sb { [void]$sb.AppendLine($_) }

        $this.HelpBlock | sb
        $this.HeaderBlock | sb
        $this.ParameterBlock | sb
        $this.MainBlock | sb
        $this.FooterBlock | sb
        $sb.ToString()
        [void]$sb.Clear()
        Remove-Variable sb
        
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'FunctionText'
        Value = $FunctionText
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam 

    ###

    # try to create a script block
    $ScriptBlock = {
        try {
            [scriptblock]::Create($this.FunctionText)

            $this.parent.SyntaxCheckPass = $true
            }
        catch {
            $this.parent.SyntaxCheckPass = $false
            $this.parent.SyntaxCheckError = $Error[0]
            }
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'ScriptBlock'
        Value = $ScriptBlock
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam 

    ###

    # create some helper functions
    $HelperFunctionsBlock = {

        # add API parameters handling only if there is any
        if ($apiParameters = $this.parent.Params | ? {$_.API -eq $true}) {
            function ToArrayDef {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory=$true,
                            ValueFromPipeline=$true,
                            Position=0)]
                $array
                )
                ( $array | % { "'{0}'" -f $_ } ) -join ', '
                }

            # create deafult block with all API parameters
            $usage = 'Api'

            '${0}Parameters = @({1})' -f $usage, (ToArrayDef $apiParameters.Name)
            '$hash{0}Parameters = @{{}}' -f $usage
            ''
            'foreach ($par in $hash{0}Parameters) {{' -f $usage
            '    if ($PSBoundParameters.Keys -contains $par) {{' -f $usage
            '        $hash{0}Parameters.Add($par, $PSBoundParameters[$par])' -f $usage
            '        }'
            '    }'
            ''


            # if there are parameters with defined usage, create a separate variables for each usage
            $uniqueUsedIn = $this.parent.Params | ? {$_.UsedIn} | Select-Object -Property UsedIn -Unique -ExpandProperty UsedIn

            foreach ($usage in $uniqueUsedIn) {
                $paramsWithThisUsage = $this.parent.Params | ? {$_.UsedIn -eq $usage}

                '${0}Parameters = @({1})' -f $usage, (ToArrayDef $paramsWithThisUsage.name)
                '$hash{0}Parameters = @{{}}' -f $usage
                ''
                'foreach ($par in ${0}Parameters) {{' -f $usage
                '    if ($PSBoundParameters.Keys -contains $par) {{' -f $usage
                '        $hash{0}Parameters.Add($par, $PSBoundParameters[$par])' -f $usage
                '        }'
                '    }'
                ''

                }

            } # End if ($apiParameters = $this.parent.Params

        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'HelperFunctionsBlock'
        Value = $HelperFunctionsBlock
        Force = $true
        }
    Add-Member -InputObject $obj.PS @memberParam 

    ###

    #return object
    $obj
    }