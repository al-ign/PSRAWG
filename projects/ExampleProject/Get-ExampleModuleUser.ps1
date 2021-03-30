<#
.Synopsis
   Find a user by name
.DESCRIPTION
   Invoke searchUser
   Alias: Invoke-ExampleModuleSearchUser
.NOTES
   API Function Name: searchUser
   PS Module Safe Name: Invoke-ExampleModuleSearchUser
#>
function Get-ExampleModuleUser {
[CmdletBinding()]
[Alias('Invoke-ExampleModuleSearchUser')]
Param (
    # Username to search for
    [string]$Username,

    # Only search for users with status
    [int]$Status,

    # Auth token to access API
    [Parameter(Mandatory=$true)]
    [string]$Token,

    # API URI
    [Parameter(Mandatory=$true)]
    [string]$Uri
    )
Begin {
$ApiParameters = @('Username', 'Status')
$hashApiParameters = @{}

foreach ($par in $hashApiParameters) {
    if ($PSBoundParameters.Keys -contains $par) {
        $hashApiParameters.Add($par, $PSBoundParameters[$par])
        }
    }

$QueryParameters = @('Username', 'Status')
$hashQueryParameters = @{}

foreach ($par in $QueryParameters) {
    if ($PSBoundParameters.Keys -contains $par) {
        $hashQueryParameters.Add($par, $PSBoundParameters[$par])
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
        function = 'searchUser'
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

