# Write-ApiFunctions.ps1

$outputPath = 'C:\Shares\personal\projects\ModuleName\Public'

$i = 0
foreach ($thisFunction in $Functions) {
    Write-Progress -Activity $thisFunction.PSFunctionName -Status 'Writing' -PercentComplete ($i/$Functions.Count*100)
    $i++
    $thisFunction.PS.FunctionText | Set-Content -LiteralPath (Join-Path $outputPath ('{0}.ps1' -f $thisFunction.PSFunctionName ))
    }
