$asParser = [AngleSharp.Html.Parser.HtmlParser]::new()

foreach ($topic in $arrToc) {
    

    $iwr = Invoke-WebRequest -UseBasicParsing -Uri $topic.Path
    $as = $asParser.ParseDocument($iwr.content)
    $topic.IWR = $iwr
    $topic.AS = $as
    Start-Sleep -Seconds 1
    }