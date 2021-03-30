<#
.Synopsis
   Create a credential object for use with Kanboard cmdlets
.DESCRIPTION
   Credential object for use with Kanboard cmdlets
.EXAMPLE
    $KBCredential = New-KanboardCredential https://example.org/jsonrpc.php jsonrpc 44a767f47c8bf7885f6d0a8b052445f9d2618ed3350d2453e2b1baa860b2
    Get-KBAllProjects -Credential $kbCred 
.EXAMPLE
    # using splatting
    $splat = @{
        Credential = New-KanboardCredential https://example.org/jsonrpc.php Username Password
        }
    Get-KBAllUsers @splat
#>
function New-KanboardCredential {
    [CmdletBinding()]
    [Alias('New-KBCredential')]
    [OutputType([hashtable])]
    Param (
        # Kanboard API URL
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$ApiUri,

        # Username
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]$ApiUsername,

        # Password or API token
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [Alias("Token")]
        [string]$ApiPassword

    )

    $SecureStringApiPassword = ConvertTo-SecureString $ApiPassword -AsPlainText -Force
    
    $Credential = [System.Management.Automation.PSCredential]::new($ApiUsername, $SecureStringApiPassword)
    
    @{
        Uri = $ApiUri
        Credential = $Credential
        }
    
    }