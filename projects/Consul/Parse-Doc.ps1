cls
# requires $arrToc

$functions = @()

foreach ($topic in $arrToc[6]) {
    
    #select all headers 
    
    $Headers = @($topic.AS.all | ? {$_.ClassName -eq 'g-type-display-3'})
    'Headers: {0}' -f $Headers.Count | Write-Host -BackgroundColor Green -ForegroundColor Black
   
    $arr = @()
    
    foreach ($i in (0..$headers.GetUpperBound(0))) {
    
        $arr += [PSCustomObject]@{
            Dir = $topic.dir
            Topic = $Topic.Name
            Title = $null
            Synopsis = $null
            Description = $null
            Method = $null
            Parameters = @()

            Block = @{
                Header = $Headers[$i]
                Method = @()
                Parameter = @()
                }
            Href = $topic.Path
            }
        }

    foreach ($node in $arr) {
    
        $node.Synopsis = $node.Block.Header.TextContent -replace '^\W'
    
        $parent = $node.Block.Header.Parent
        $node.Title = $parent.FirstChild.TextContent -replace '^\W'
    
        $node.Description = $node.Block.Header.NextElementSibling.TextContent
        if ($topic.Dir) {
            '{2} - {0}: {1}' -f $Topic.Name, $node.Title, $topic.dir | Write-Host -BackgroundColor DarkBlue
            }
        else {
            '{0}: {1}' -f $Topic.Name, $node.Title | Write-Host -BackgroundColor DarkBlue
            }
        
        $node.Synopsis | Write-Host -BackgroundColor DarkGreen

        $node.Description | Write-Host -BackgroundColor DarkYellow
        
        # iterate over siblings

        $a = $node.Block.Header

        # oh bother
        $maxI = 15
        for ($i = 0; $i -lt $maxI; $i++) {
             write-host ("$I " * 3) -BackgroundColor DarkCyan -NoNewline
             $nextElement.ClassName |Write-Host -BackgroundColor DarkGray -ForegroundColor White
            $nextElement = $a.NextElementSibling
            $nextElement.TextContent -replace '[\r\n]+'
        
            if ($nextElement.TextContent -match 'MethodPath') {
                $node.Block.Method += $nextElement
                }

            if ($a.TextContent -match 'Parameters$') {
                $node.Block.Parameter += [pscustomobject]@{
                    ParameterBlockName = $a.TextContent -replace '^\W'
                    Block = $nextElement
                    }
                }

            if ($nextElement.ClassName -eq 'g-type-display-3') {
                'Stop loop: Next function header' | Write-Host -BackgroundColor DarkRed
                $i = $maxI
                }

            if ($nextElement.TextContent -match 'Sample') {
                'Stop loop: Sample' | Write-Host -BackgroundColor DarkRed
                $i = $maxI
                }
            $a = $nextElement
            }
    
        ###

        #parse method block

        if ($node.Block.Method) {
            
            
            $methodTable = $node.Block.Method.ChildNodes.ChildNodes 

            #init
            $node.Method = @()
            
            # table header
            $thead = $node.Block.Method.ChildNodes | ? TagName -eq THEAD

            # how many COLS are there (zero-based)
            $colCount = @($thead.ChildNodes.childnodes).GetUpperBound(0)

            # rows
            $tBody = @($node.Block.Method.ChildNodes.ChildNodes | ? TagName -eq TR | ? {$_.FirstElementChild.GetType().Name -notmatch 'TableHeader'})

            foreach ($row in $tBody) {

                $obj = [pscustomobject]@{}

                foreach ($i in (0..$colCount)) {

                    $splat = @{
                        InputObject = $obj 
                        NotePropertyName = $thead.ChildNodes.childnodes[$i].TextContent
                        NotePropertyValue = $row.ChildNodes[$i].TextContent
                        }
                    Add-Member @splat

                    }

                $node.Method += $obj
                
                }# End % row

        } # End if $node.Block.Method
    
        ###

        # parse parameters block
    
        filter te {
            param ($ParameterBlockName)

            $in = $_
        
            $regex = '\s*(?<name>\w+)\s+\((?<type>[\w<>]+)\s*:\s*(?<default>.+?)\)(?: - )*\s*(?<desc>[\w\W]+)' 
    
            $ss = Select-String -InputObject $in.TextContent -Pattern $regex -AllMatches

            foreach ($s in $ss.Matches) {
                    $obj = [pscustomobject]@{
                        Name = $s.Groups['name'].Value
                        Type = $s.Groups['type'].Value
                        Desc = $s.Groups['desc'].Value
                        Default = $s.Groups['default'].Value
                        UsedIn = $null
                        ParameterBlockName = $ParameterBlockName
                        }
                    if ($obj.Desc -match ('This is specified as part of the URL as a query parameter' -replace ' ','[\W]')) {
                        $obj.UsedIn = 'query'
                        }
                    $obj
                    }    
            } # End filter

       
        foreach ($member in $node.Block.Parameter) {
            'Parsing parameter Block "{0}"' -f $member.ParameterBlockName | Write-Host -BackgroundColor DarkMagenta
            $node.Parameters += $member.Block.ChildNodes | te -ParameterBlockName $member.ParameterBlockName
            }
        'Parameters count: {0}' -f $node.Parameters.Count| Write-Host -BackgroundColor DarkMagenta
        'END OF HEADER'
        ''
        }

    'END TOPIC'

    foreach ($member in $arr) {
        $functions += $member
        }
    }# End % topic