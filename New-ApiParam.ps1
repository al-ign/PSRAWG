function New-ApiParam {
param (
    # Name of the parameter
    [string]$Name,

    # Used in API query (true) or something else
    # this property is used to generate helper functions
    [bool]$API = $true,

    # PowerShell/.NET type
    $Type = $null,

    # Mark if the parameter is mandatory
    [bool]$Required = $false,

    # Text description
    $Description,

    # Alias
    $Alias,

    # ParameterSetName 
    $ParameterSetName,

    # Parameter position name
    $Position,

    # Where the parameter is used, eg. Headers, Body
    $UsedIn = $null
    )

    $obj = [pscustomobject]@{
        Name = $Name
        API = $API
        Type = $Type
        Required = $Required
        Description = $Description
        Alias = $Alias
        ParameterSetName = $ParameterSetName
        Position = $Position
        UsedIn = $UsedIn
        }


    # create a PS script parameter definition
    $PSParameter = {
        $arrStr = @()
        if ($this.Description) {
            $arrStr += '    # {0}' -f $this.Description
            }
        if ($this.Required -or $this.ParameterSetName) {
            $arrParam = @()
            
            if ($this.Required -eq 'True') {
                $arrParam += 'Mandatory=$true'
                }
            
            if ($this.ParameterSetName) {
                $arrParam += "ParameterSetName='{0}'" -f $this.ParameterSetName
                }

            $arrStr += '    [Parameter({0})]' -f ($arrParam -join ', ')
            } # end parameter parameters
            
        if ($this.Alias) {
            $arrStr += "    [Alias('{0}')]" -f $this.Alias
            }

        if ($this.Type) {
            $arrStr += '    [{1}]${0}' -f $this.Name, $this.Type
            }
        else {
            $arrStr += '    ${0}' -f $this.Name
            }

        $arrStr

        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'PSParameter'
        Value = $PSParameter
        Force = $true
        }
    Add-Member -InputObject $obj @memberParam 

    $obj
    }