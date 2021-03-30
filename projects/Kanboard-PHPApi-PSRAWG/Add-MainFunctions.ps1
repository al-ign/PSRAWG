#Add-MainFunctions

foreach ($thisFunction in $Functions) {

    # add credentials handling block

    if ($thisFunction.Params | ? Name -eq Credential) {
        $thisFunction.PS.BeginBlock += @'
if ($PSCmdlet.ParameterSetName -eq 'PlainCredentials') {
    $Credential = New-KanboardCredential $ApiUri $ApiUsername $ApiPassword
    }
'@


        }

# Create JSON block
$thisFunction.PS.EndBlock += @'
$jsonRequestId = Get-Random -Minimum 1 -Maximum ([int]::MaxValue)

$json = @{
    jsonrpc = '2.0'
    method = '$$$Method$$$'
    id = $jsonRequestId        
    }

# dynamically add user parameters
if ($hashJsonParameters.Count -gt 0) {
    $json.Add('params', $hashJsonParameters)
    }

$json = $json | ConvertTo-Json
    
if ($PSBoundParameters['Verbose']) {
    Write-Verbose $json
    }

'@ -replace [regex]::Escape('$$$Method$$$'),$thisFunction.ApiFunctionName

$thisFunction.PS.EndBlock += @'
$splat = @{
    Method = 'POST'
    Uri = $Credential.Uri
    Credential = $Credential.Credential
    Body = $json
    ContentType = 'application/json'
    }

$res = Invoke-RestMethod @splat

if ($res.result) {
    Convert-KanboardResult $res.result -PassThru
    }

'@

    }