$gen = @()

foreach ($f in $functions) {
    $a = New-ApiObject -NounPrefix Consul -ApiFunctionName ($f.title + ' ' + $f.Synopsis)
    $a.Verb = $f.Method[0].Method
    $a.Noun = 'Key'
    $a.doc.Synopsis = $f.Synopsis
    $a.doc.Description = $f.Description

    #$f.Parameters | select name, type,usedin, desc
    $par = @()
    foreach ($p in $f.Parameters) {
        $splat = @{
            Name = $p.name
            Type = $p.type
            Description = $p.desc -replace '[\r\n]+',' '
            UsedIn = $p.usedIn 
            }
        $par += New-ApiParam @splat
        }

    $a.Params = $par
    $gen += $A


# add Endblock code
$endblock = @'

    if ($hashQueryParameters) {
        
        $query = '?' + (
            (
                $hashQueryParameters.psbase.Keys | % {
                    '{0}={1}' -f $_, $hashQueryParameters.$_
                    }    
                ) -join '&'
            )
        }

    $splat = @{
        Method = 'zxcMETHODzxc'
        Uri = '{0}/v1zxcPATHzxc{1}{2}' -f $ApiUri, $Key, $query

        ContentType = 'application/json'
        }

    if ($splat.Method -eq 'PUT') {
        $splat.Add('Body',$Value)
        }
        
    if ($Token) {
        $headers = @{
            'X-Consul-Token' = $token
            }
        $splat.Add('Headers',$headers)
        }

    $irm = Invoke-RestMethod   @splat -Verbose
    $irm
'@ -replace 'zxcMETHODzxc',$f.Method[0].Method -replace 'zxcPATHzxc',($f.Method[0].Path -replace '\:\w+')

    $a.ps.EndBlock = $endblock





    } 

# fix verbs
foreach ($g in $gen) {
    switch -Regex ($g.Verb) {
        'GET' {$g.verb = 'Get'}
        'PUT' {$g.verb = 'Set'}
        'DELETE' {$g.verb = 'Remove'}

        }
    }


# add auth token
foreach ($g in $gen) {
        $splat = @{
            Name = 'ApiToken'
            Type = 'string'
            Description = 'Authentication token'
            UsedIn = 'auth'
            }
        $g.Params += New-ApiParam @splat

        $splat = @{
            Name = 'ApiUri'
            Type = 'string'
            Description = 'Consul URI'
            UsedIn = 'auth'
            Required = $true
            }
        $g.Params += New-ApiParam @splat
    }

# add a parameter to supply the value for the key
$gen | ? PSFunctionName -EQ 'Set-ConsulKey' | % {
    $g = $_
            $splat = @{
            Name = 'Value'
            
            Description = 'Key Value'
            UsedIn = 'body'
            }
        $g.Params += New-ApiParam @splat
    }

$gen | ? PSFunctionName -EQ 'Get-ConsulKey' | % {
    $g = $_
    $g.Params | where Type -eq bool | % {$_.Type = 'switch'}

    $g.ps.BeginBlock = @'
class ConsulKey {
    [int]$CreateIndex
    [int]$Flags
    [string]$Key
    [int]$LockIndex
    [int]$ModifyIndex
    [string]$Value

    [string] ToASCII () {
        return [System.Text.Encoding]::ASCII.GetString(
            [System.Convert]::FromBase64String($this.Value)
            )
        }

    [string] ToUnicode () {
        return [System.Text.Encoding]::Unicode.GetString(
            [System.Convert]::FromBase64String($this.Value)
            )
        }

    }
'@

$getConsulKeyCustom = @'
    #map to the class if not recurse
    if ($PSBoundParameters.psbase.Keys -match 'keys|recurse|raw') {
        $irm
        }
    else {
        foreach ($thisResponse in $irm) {
            [ConsulKey]$thisResponse
            }
        }
'@

$g.ps.EndBlock = $g.ps.EndBlock -replace '(\$irm)(?!\s+=\s+Invoke)',$getConsulKeyCustom
    }

# initilize scriptproperty
$gen.ps.ScriptBlock | Out-Null

$gen | select ApiFunctionName, Verb, PSFunctionName, SyntaxCheckPass | ft