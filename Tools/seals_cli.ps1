param (
    [Parameter(Mandatory = $false)][switch]$new,
    [Parameter(Mandatory = $false)][switch]$generate,
    [Parameter(Mandatory = $false)][switch]$update,
    [Parameter(Mandatory = $true)][string]$name,
    [Parameter(Mandatory = $false)][string]$from,
    [Parameter(Mandatory = $false)][switch]$exclude,
    [Parameter(Mandatory = $false)][string]$groups
)

Write-Host generate $generate
Write-Host update $update
Write-Host name $name
Write-Host exclude $exclude
Write-Host groups $groups

function GenerateModlistGroupFile{
    Param(
        $name,
        $excludeWeaponNames,
        $outputFile,
        $modName
    )


    # Clear previous output if exists
    if (Test-Path $outputFile) {
        Remove-Item $outputFile
    }

    # Path to miss report and files
    $noMatchesPath = ".\generation\output\miss\no_matches.ltx"
    $noMatchesFilesPath = ".\generation\output\miss\files"
    if (Test-Path $noMatchesFilesPath) {
        Remove-Item $noMatchesFilesPath -Recurse
    }
    New-Item -Path $noMatchesFilesPath -ItemType Directory

    # Path to hit report and files
    $hitPath = ".\generation\output\hit\"
    $hitPathFilesPath = ".\generation\output\hit\files"
    if (Test-Path $hitPathFilesPath) {
        Remove-Item $hitPathFilesPath -Recurse
    }
    New-Item -Path $hitPathFilesPath -ItemType Directory

    # Use a hash set for uniqueness
    $weaponSet = [System.Collections.Generic.HashSet[string]]::new()
    $noMatchesList = @()

    $src = "."
    if ($null -ne $modName){
        $src = "..\$modName"
        # Verify the mod exists
        if (-not (Test-Path -Path $src)) {
            Write-Error "$src does not exist."
            return
        }
    }

    # Search for files recursively with names starting with npc_loadouts
    Get-ChildItem -Path "$src\gamedata\configs" -Recurse -File | Where-Object { 
        $_.Name -like "new_game_loadouts*" -or  
        $_.Name -like "mod_new_game_loadouts*" -or  
        $_.Name -like "npc_loadouts*" -or 
        $_.Name -like "mod_npc_loadouts*" 
    } | ForEach-Object {
        $content = Get-Content $_.FullName
        
        $fileWeaponSet = [System.Collections.Generic.HashSet[string]]::new()
        $count = 0        
        
        foreach ($line in $content) {
            
            # Find all matching wpn_ strings with the format weapon:N:N:N
            if ($line -match "^\s*[!\[]?(wpn_[a-zA-Z0-9_]+)[\]]?\s*(?::.*|=\s*.*)?$") {
                $count = $count + 1
                # Write-Host found $matches[1]
                $weaponName = $matches[1]
                $fileWeaponSet.Add($weaponName) | Out-Null
                $count = $count + 1
            }
        }
        if ($count -eq 0){
            Write-Host no matches in $_.FullName
            # add the file to the no matches files list
            $noMatchesList += $_.FullName
            # save the input scanned file
            Copy-Item -Path $_.FullName -Destination "$noMatchesFilesPath\$($_.Name)"
        }else{
            foreach($section in $fileWeaponSet){
                if ($excludeWeaponNames -notcontains $section){
                    $weaponSet.Add($section) | Out-Null
                }
            }
            # save the hit reports to dedicated file
            $fileWeaponSet | Set-Content -Path "$hitPath\$_"
            # save the input scanned file
            Copy-Item -Path $_.FullName -Destination "$hitPathFilesPath\$($_.Name)"
        }
    }

    # Add header and sort
    $header = "[$name]"
    $finalOutput = @($header) + ($weaponSet | Sort-Object)

    # Write to file
    $finalOutput | Set-Content -Path $outputFile
    $noMatchesList | Set-Content -Path $noMatchesPath

    Write-Host " Done! Unique section names saved to $outputFile"
    Write-Host " Done! Logged all the hit to $hitPath in MO2 overwrite folder"
    Write-Host " Done! Logged all the miss to $noMatchesPath in MO2 overwrite folder"

}

function NameTemplate{
    Param(
        $templatePath,
        $name
    )    

    # Get all text-based files recursively
    $files = Get-ChildItem -Path $templatePath -Recurse -File

    foreach ($file in $files) {
        try {

            # Rename file if filename contains "default"
            if ($file.Name -like "*default*") {
                $newName = $file.Name -replace "default", $name
                $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newName
                Rename-Item -Path $file.FullName -NewName $newPath
                Write-Host "Renamed: $($file.Name) → $newName"
            }
        }
        catch {
            Write-Warning "Failed to process $($file.FullName): $_"
        }
    }
}

function Templating{
    Param(
        $templatePath,
        $tokens
    )    

    # Get all text-based files recursively
    $files = Get-ChildItem -Path $templatePath -Recurse -File

    foreach ($file in $files) {
        try {
            $content = Get-Content -Path $file.FullName -Raw

            foreach ($key in $tokens.Keys) {
                $content = $content -replace [regex]::Escape("{{${key}}}"), $tokens[$key]
            }

            $content | Set-Content -Path $file.FullName
            Write-Host "Processed: $($file.FullName)"
        }
        catch {
            Write-Warning "Failed to process $($file.FullName): $_"
        }
    }    
}

function CreateSealsTemplateProject{

    $templateScaffoldPath = "generation/templates/gamedata"
    

    if (Test-Path -Path $templateScaffoldPath) {

        $templatePath = "generation/output/gamedata"

        # Verify the gamedata exists
        if (Test-Path -Path $templatePath) {
            Remove-Item $templatePath -Recurse -Force | Out-Null
            
        }

        Copy-Item -Path $templateScaffoldPath -Destination $templatePath -Recurse

        # Verify the gamedata exists
        if (-not (Test-Path -Path $templatePath)) {
            Write-Error "$templatePath does not exist."
            return
        }
    }else{
        $templatePath = "./gamedata"
    }
    
    $TokensFile = "template.ini"

    if (-not (Test-Path -Path $TokensFile)) {
        Write-Error "Tokens file '$TokensFile' does not exist."
        return
    }

    # Read token-value pairs from the file
    $tokens = @{}
    foreach ($line in Get-Content -Path $TokensFile) {
        if ($line -match "^\s*(\w+)\s*=\s*(.+)\s*$") {
            $tokens[$matches[1]] = $matches[2]
        }
    }

    Templating $templatePath $tokens

    NameTemplate $templatePath $tokens["sealid"]
}


# handling exclude
$excludeWeaponNames = @()
if ($exclude.IsPresent){

    $groupNames = $groups -split ','

    foreach( $groupName in $groupNames){
        $sectionList = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_$groupName.ltx"
        $excludeWeaponNames = ($excludeWeaponNames + $sectionList) | Sort-Object -Unique 
    }
}


# update
if ($update.IsPresent) {
    Write-Host " Warning!! you are generating with UPDATE intent"
    Write-Host " Close window or continue"

    Write-Host
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');    

    $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
    GenerateModlistGroupFile $name $excludeWeaponNames $outputFile $from
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

# generate
if ($generate.IsPresent) {
    $outputFile = ".\generation\output\seals_group_$name.ltx"
    GenerateModlistGroupFile $name $excludeWeaponNames $outputFile $from
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

# new
if($new.IsPresent){
    CreateSealsTemplateProject

    if ($null -ne $from){
        $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
        GenerateModlistGroupFile $name $excludeWeaponNames $outputFile $from
    }
}

