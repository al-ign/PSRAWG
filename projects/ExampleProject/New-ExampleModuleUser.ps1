<#
.Synopsis
   Create a new user
.DESCRIPTION
   Invoke createUser
   Alias: Invoke-ExampleModuleCreateUser
.NOTES
   API Function Name: createUser
   PS Module Safe Name: Invoke-ExampleModuleCreateUser
#>
function New-ExampleModuleUser {
[CmdletBinding()]
[Alias('Invoke-ExampleModuleCreateUser')]
Param (
    # Username for the new user
    [Parameter(Mandatory=$true)]
    [string]$Username,

    # Password for the new user
    [Parameter(Mandatory=$true)]
    [string]$Password,

    # Auth token to access API
    [Parameter(Mandatory=$true)]
    [string]$Token,

    # API URI
    [Parameter(Mandatory=$true)]
    [string]$Uri
    )
Begin {
$ApiParameters = @('Username', 'Password')
$hashApiParameters = @{}

foreach ($par in $hashApiParameters) {
    if ($PSBoundParameters.Keys -contains $par) {
        $hashApiParameters.Add($par, $PSBoundParameters[$par])
        }
    }

$HeadersParameters = @('Username', 'Password')
$hashHeadersParameters = @{}

foreach ($par in $HeadersParameters) {
    if ($PSBoundParameters.Keys -contains $par) {
        $hashHeadersParameters.Add($par, $PSBoundParameters[$par])
        }
    }

$AuthParameters = @('Token', 'Uri')
$hashAuthParameters = @{}

foreach ($par in $AuthParameters) {
    if ($PSBoundParameters.Keys -contains $par) {
        $hashAuthParameters.Add($par, $PSBoundParameters[$par])
        }
    }

} # End begin block

End {
    $json = @{
        jsonrpc = '2.0'
        function = 'createUser'
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

} # End end block


} # End  function

