
$asParser = [AngleSharp.Html.Parser.HtmlParser]::new()

#$iwr = Invoke-WebRequest -UseBasicParsing -Uri https://www.consul.io/api-docs

$as = $asParser.ParseDocument($iwr.content)

$FQDN = 'https://www.consul.io'

$docsnav = $as.All | ? Classlist -contains docs-nav | ? Localname -eq ul
$docsnav = $docsnav.ChildNodes | ? ChildElementCount -gt 0

$arrToc = @()


# no descendant topics
foreach ($single in ($docsnav | ? ChildElementCount -eq 1)) {
    $obj = [pscustomobject]@{
        Dir = $null
        Name = $single.TextContent
        Path = $Single.Attributes |? Name -eq data-testid | select -ExpandProperty value
        IWR = $null
        AS = $null
        }
    $obj.Path = '{0}{1}' -f $FQDN, $obj.Path
    
    $arrToc += $obj
    }

# 'folders'
foreach ($single in ($docsnav | ? ChildElementCount -ne 1)) {

        $single.ChildNodes.ChildNodes | % {
        $z = $_

        # skip container link
        if ($z.children.classname -contains 'chevron') {
            
            }
        else {
            $obj = [pscustomobject]@{
                Dir = $single.ChildNodes[0].TextContent -replace '^\s*'
                Name = $_.TextContent
                Path = $_.attributes |? Name -eq data-testid | select -ExpandProperty value
                IWR = $null
                AS = $null
                }
            $obj.Path = '{0}{1}' -f $FQDN, $obj.Path
            
            $arrToc += $obj
            }
        }
    
    }    

# exclude pages
$excludeList = '(/features)|(/libraries)|(/index)'

$arrToc = $arrToc | ? Path -NotMatch $excludeList