

$text = @'
Create Session

This endpoint initializes a new session. Sessions must be associated with a node and may be associated with any number of checks.
Method	Path	Produces
PUT	/session/create	application/json

The table below shows this endpoint's support for blocking queries, consistency modes, agent caching, and required ACLs.
Blocking Queries	Consistency Modes	Agent Caching	ACL Required
NO	none	none	session:write
»Parameters

    ns (string: "") Enterprise    
    - Specifies the namespace to query. If not provided, the namespace will be inferred from the request's ACL token, or will default to the default namespace. This is specified as part of the URL as a query parameter. Added in Consul 1.7.0.

    dc (string: "") - Specifies the datacenter to query. This will default to the datacenter of the agent being queried. This is specified as part of the URL as a query parameter. Using this across datacenters is not recommended.

    LockDelay (string: "15s") - Specifies the duration for the lock delay. This must be greater than 0.

    Node (string: "<agent>") - Specifies the name of the node. This must refer to a node that is already registered.

    Name (string: "") - Specifies a human-readable name for the session.

    Checks (array<string>: nil) - specifies a list of associated health check IDs (commonly CheckID in API responses). It is highly recommended that, if you override this list, you include the default serfHealth.

    Behavior (string: "release") - Controls the behavior to take when a session is invalidated. Valid values are:
        release - causes any locks that are held to be released
        delete - causes any locks that are held to be deleted

    TTL (string: "") - Specifies the duration of a session (between 10s and 86400s). If provided, the session is invalidated if it is not renewed before the TTL expires. The lowest practical TTL should be used to keep the number of managed sessions low. When locks are forcibly expired, such as when following the leader election pattern in an application, sessions may not be reaped for up to double this TTL, so long TTL values (> 1 hour) should be avoided. Valid time units include "s", "m" and "h".
'@

$function = [pscustomobject]@{
    Name = $null
    Synopsis = $null
    Description = $null
    Definition = $null
    Text = $null
    ParamText = $null
    ParamApi = $null
    Method = $null
    Path = $null
    Produces = $null
    }

    # parameters
    $ParamScript = {

        $regex = '\s*(?<name>\w+)\s+\((?<type>[\w<>]+)\s*:\s*(?<default>.+?)\)(?: - )*\s*(?<desc>.+)' 
        $ss = Select-String -InputObject $This.text -Pattern $regex -AllMatches

        $this.paramApi = foreach ($s in $ss.Matches) {
            $obj = [pscustomobject]@{
                Name = $s.Groups['name'].Value
                Type = $s.Groups['type'].Value
                Desc = $s.Groups['desc'].Value
                Default = $s.Groups['default'].Value
                UsedIn = $null
                }
            if ($obj.Desc -match 'This is specified as part of the URL as a query parameter') {
                $obj.UsedIn = 'query'
                }
            $obj
            }        

        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'ParamScript'
        Value = $ParamScript
        Force = $true
        }
    Add-Member -InputObject $function @memberParam 
    
    # Synopsis
    $SynopsisScript = {
        if ($this.Text -match '.+') {
            $this.Synopsis = $Matches[0]
            }
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'SynopsisScript'
        Value = $SynopsisScript
        Force = $true
        }
    Add-Member -InputObject $function @memberParam 
    
    # MethodScript
    $MethodScript = {
        $regex = '(?:Method\s+Path\s+Produces)[\r\n]+?(?<method>\w+)\s+(?<path>[\w:/]+)\s+(?<produces>[\w:/]+).+?[\r\n]'
        if ($this.Text -match $regex) {
            $this.Method = $Matches.Method
            $this.Path = $Matches.path
            $this.Produces = $Matches.produces
            }
        }

    $memberParam = @{
        MemberType = 'ScriptProperty'
        Name = 'MethodScript'
        Value = $MethodScript
        Force = $true
        }
    Add-Member -InputObject $function @memberParam 
    

$function.Text = $text

$function.ParamScript
$function.SynopsisScript
$function.MethodScript
$function | fl