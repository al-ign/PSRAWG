
foreach ($thisFunction in $Functions) {

    if ($thisFunction.Params | ? Name -eq Credential) {
        }
    else {
        $thisFunction.PS.DefaultParameterSetName = 'PlainCredentials'

        $splat = @{
        Description = 'Credential Object'
        ParameterSetName = 'CredentialObject'
        Required = $true
        Name = 'Credential'
        API = $false
        }

        $thisFunction.params += New-ApiParam @splat

        $splat = @{
        Description = 'Kanboard API Uri'
        ParameterSetName='PlainCredentials'
        Required = $true
        Type = 'string'
        Name = 'ApiUri'
        API = $false
        }

        $thisFunction.params += New-ApiParam @splat

        $splat = @{
        Description = 'API Username, use "jsonrpc" for the global access'
        ParameterSetName='PlainCredentials'
        Required = $true
        Type = 'string'
        Name = 'ApiUsername'
        API = $false
        }

        $thisFunction.params += New-ApiParam @splat

        $splat = @{
        Description = 'API Password or Token'
        ParameterSetName='PlainCredentials'
        Required = $true
        Type = 'string'
        Name = 'ApiPassword'
        Alias = 'Token'
        API = $false
        }

        $thisFunction.params += New-ApiParam @splat

        }
    }