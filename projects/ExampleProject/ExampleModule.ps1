$functions = @()

# 1st function
$api = @{
    NounPrefix = 'ExampleModule'
    ApiFunctionName = 'createUser'
    }

$api =  New-ApiObject @api
$functions += $api

# parameters
$parameter = @{
    Name = 'Username'
    Description = 'Username for the new user'
    Type = 'string'
    Required = $true
    UsedIn = 'Headers'
    }

$api.Params += New-ApiParam @parameter

$parameter = @{
    Name = 'Password'
    Description = 'Password for the new user'
    Type = 'string'
    Required = $true
    UsedIn = 'Headers'
    }

$api.Params += New-ApiParam @parameter

# for the help block
$api.DOC.Synopsis = 'Create a new user'

# 2nd function 

$api = @{
            NounPrefix = 'ExampleModule'
            ApiFunctionName = 'searchUser'
            }

$api =  New-ApiObject @api

$functions += $api

# parameters
$parameter = @{
    Name = 'Username'
    Description = 'Username to search for'
    Type = 'string'
    Required = $false
    UsedIn = 'Query'
    }

$api.Params += New-ApiParam @parameter

$parameter = @{
    Name = 'Status'
    Description = 'Only search for users with status'
    Type = 'int'
    Required = $false
    UsedIn = 'Query'
    }

$api.Params += New-ApiParam @parameter

# for the help block

$api.DOC.Synopsis = 'Find a user by name'

# add auth token and uri parameter for all functions

foreach ($f in $functions) {

    $parameter = @{
        Name = 'Token'
        Description = 'Auth token to access API'
        Type = 'string'
        Required = $true
        UsedIn = 'Auth'
        API = $false
        }

    $f.params += New-ApiParam @parameter

    $parameter = @{
        Name = 'Uri'
        Description = 'API URI'
        Type = 'string'
        Required = $true
        UsedIn = 'Auth'
        API = $false
        }

    $f.params += New-ApiParam @parameter

    
    }

# create PoSh verbNouns
foreach ($f in $functions) {
    switch -regex ($f.ApiFunctionName) {
    
    '(create)(.+)' {
        $f.Verb = 'New'
        $f.Noun = $Matches[2]
        }

    '(search)(.+)' {
        $f.Verb = 'Get'
        $f.Noun = $Matches[2]
        }
    }
}

# add actual code

foreach ($f in $functions) {

$f.ps.EndBlock = @'
    $json = @{
        jsonrpc = '2.0'
        function = $f__ApiFunctionName
        }

    $json.Add('Token', $hashAuthParameters['Token'])

    if ($hashHeadersParameters.Count -gt 0) {
        $json.Add('Params', $hashHeadersParameters)
        }

    $json = $json | ConvertTo-Json

    $uri = [uri]::new($hashAuthParameters['Uri'])
    $QueryParameters = @('Username', 'Status')
    
    if ($hashQueryParameters) {
        
        $query = '?' + (
            (
                $hashQueryParameters.Keys | % {
                    '{0}={1}' -f $_, $hashQueryParameters.$_
                    }    
                ) -join '&'
            )
        
        $uri = [uri]::new($uri,[string]$query)
        }

    $splat = @{
        Method = 'POST'
        Uri =     $uri
        Body = $json
        ContentType = 'application/json'
        }
    
    # $res = Invoke-RestMethod @splat

    write-host "Invoking Invoke-RestMethod:"
    'Uri: {0}' -f $uri
    'Body:'
    $splat.body

'@ -replace '\$f__ApiFunctionName',("'{0}'" -f $f.ApiFunctionName)

    }

# let's see what we got:

foreach ($f in $functions) {
    'PS function {0} for API function {1}' -f $f.PSFunctionName, $f.ApiFunctionName | Write-Host -ForegroundColor Green
    $f.Params | select Name, API, Type, Required, Description, UsedIn | ft
    }

# write function files

foreach ($f in $functions) {
    
   $f.PS.FunctionText | Set-Content -LiteralPath (Join-Path $PSScriptRoot ('{0}.ps1' -f $f.PSFunctionName ))
   }