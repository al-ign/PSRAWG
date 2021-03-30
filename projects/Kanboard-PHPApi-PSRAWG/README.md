# Kanboard-PHPApi-PSRAWG

Project used to generate PS2Kanboard module https://github.com/al-ign/PS2Kanboard

# Usage

Clone Kanboard repo

Fix paths in `ConvertFrom...` scripts

Load PSRAWG functions:

    . ..\..\New-ApiObject.ps1
    . ..\..\New-ApiParam.ps1

Run the scripts in this order:

    ConvertFrom-PHPApi.ps1
    ConvertFrom-RSTDocumentation-v2.ps1
    Add-AuthenticationParameters.ps1
    Add-MainFunctions.ps1

Create output folder, copy helper scripts from `Additional scripts`

Fix path in `Write-KBApiGenFunctionFiles.ps1` and run to write script files
