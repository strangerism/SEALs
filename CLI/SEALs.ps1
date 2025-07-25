param (
    [Parameter(Mandatory = $false)][switch]$new,
    [Parameter(Mandatory = $false)][switch]$add,
    [Parameter(Mandatory = $false)][switch]$generate,
    [Parameter(Mandatory = $false)][switch]$update,
    [Parameter(Mandatory = $false)][switch]$3dss,
    [Parameter(Mandatory = $false)][string]$name,
    [Parameter(Mandatory = $false)][string]$from,
    [Parameter(Mandatory = $false)][switch]$exclude,
    [Parameter(Mandatory = $false)][string]$groups
)

Write-Host generate $new
Write-Host new $generate
Write-Host update $update
Write-Host name $name
Write-Host "from $from"
Write-Host exclude $exclude
Write-Host groups $groups

# logfile
$logpath = ".\generation\output\seals.log"
$logs = @()

function Log {
    param (
        [string]$entry,
        [ref]$logs
    )

    Write-Host $entry
    $logs.Value += $entry
}

function LogAdd {
    param (
        [string]$entry,
        [ref]$logs
    )

    Write-Host $entry -ForegroundColor Cyan
    $logs.Value += $entry
}
function LogDup {
    param (
        [string]$entry,
        [ref]$logs
    )

    Write-Host $entry -ForegroundColor Red
    $logs.Value += $entry
}

function AddModlistGroupFile{
    Param(
        $name,
        $outputFile,
        $modName
    )

    $excludeWeaponNames = @()

    GenerateModlistGroupFile $name $excludeWeaponNames ".\generation\output\$name\add.ltx" $modName

    $addSections = Get-Content ".\generation\output\$name\add.ltx"
    $nameSections = Get-Content $outputFile   
    
    $sectionNames = ($nameSections + $addSections) | Sort-Object -Unique 

    # Save unique section names to the output file
    $sectionNames | Set-Content -Path $outputFile
}

function GenerateModlistGroupFile{
    Param(
        $name,
        $excludeWeaponNames,
        $outputFile,
        $modName
    )

    Write-Host name $name
    Write-Host outputFile $outputFile
    Write-Host modName $modName
    
    # Clear previous output if exists
    if (Test-Path $outputFile) {
        Remove-Item $outputFile
    }

    # Path to miss report and files
    $noMatchesPath = ".\generation\output\$name\miss\no_matches.log"
    $noMatchesFilesPath = ".\generation\output\$name\miss\files"
    if (Test-Path $noMatchesFilesPath) {
        Remove-Item $noMatchesFilesPath -Recurse
    }
    New-Item -Path $noMatchesFilesPath -ItemType Directory

    # Path to hit report and files
    $hitPath = ".\generation\output\$name\hit\"
    $hitPathFilesPath = ".\generation\output\$name\hit\files"
    if (Test-Path $hitPathFilesPath) {
        Remove-Item $hitPathFilesPath -Recurse
    }
    New-Item -Path $hitPathFilesPath -ItemType Directory

    # Use a hash set for uniqueness
    $weaponSet = [System.Collections.Generic.HashSet[string]]::new()
    $noMatchesList = @()

    if (($null -ne $modName) -and ("" -ne $modName)){
        $src = "..\$modName\gamedata\configs"
        # Verify the mod exists
        if (-not (Test-Path -Path $src)) {
            Write-Error "$src does not exist."
            return
        } 
    }else{
        $src = "gamedata\configs"
    }

    # Search for files recursively with names starting with npc_loadouts
    Get-ChildItem -Path $src -Recurse -File | Where-Object { 
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
            $logFileName = [System.IO.Path]::ChangeExtension($_, "log")
            $fileWeaponSet | Set-Content -Path "$hitPath\$logFileName"
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

function Generate3DSSGroupFile{
    Param(
        $modlistWeaponNames,
        $outputFile,
        $modName
    )    

    # Clear previous output if exists
    if (Test-Path $outputFile) {
        Remove-Item $outputFile
    }

    # Path to miss report and files
    $noMatchesPath = ".\generation\output\3dss\miss\no_matches.log"
    $noMatchesFilesPath = ".\generation\output\3dss\miss\files"
    if (Test-Path $noMatchesFilesPath) {
        Remove-Item $noMatchesFilesPath -Recurse
    }
    New-Item -Path $noMatchesFilesPath -ItemType Directory

    # Path to hit report and files
    $hitPath = ".\generation\output\3dss\hit\"
    $hitPathFilesPath = ".\generation\output\3dss\hit\files"
    if (Test-Path $hitPathFilesPath) {
        Remove-Item $hitPathFilesPath -Recurse
    }
    New-Item -Path $hitPathFilesPath -ItemType Directory

    # Define files to ignore
    $ignoreFiles = Get-Content ".\generation\input\ignoreFiles.txt"

    # The list of 3DSS scopes
    $scopeNames = Get-Content ".\generation\input\scopes.txt"

    # the list of manually entered sections. When the generation fails, you can fall back to this file and add what is being missed
    $manualEntries = Get-Content ".\generation\input\manual_entries.ltx"

    # group header
    $header = "[3dss]"

    # Write the header to the output file first
    Set-Content -Path $outputFile -Value $header

    # Store matches in a hashset to avoid duplicates
    $sectionNames = [System.Collections.Generic.HashSet[string]]::new()

    $src = "."
    if (($null -ne $modName) -and ("" -ne $modName)){
        $src = "..\$modName"
        # Verify the mod exists
        if (-not (Test-Path -Path $src)) {
            Write-Error "$src does not exist."
            return
        }
    }

    # Scan each .ltx file with 3dss in its name
    Get-ChildItem -Path "$src\gamedata\configs" -Recurse -File -Filter "*3dss*.ltx" | Where-Object {
        $ignoreFiles -notcontains $_.Name
    } | ForEach-Object {
        $lines = Get-Content $_.FullName


        $count = 0
        $fileSectionNames = [System.Collections.Generic.HashSet[string]]::new()

        foreach ($line in $lines) {
            # Ignore comment lines
            if ($line.Trim() -like ";*") { continue }

            # Match all section formats: [name], ![name], [name_scope], ![name_scope]
            $matches = [regex]::Matches($line, "(?<marker>!?)*\[(?<raw>[^\[\]]+)\]")

            foreach ($match in $matches) {
                $raw = $match.Groups["raw"].Value
                # Log "match: $raw" ([ref]$logs)
                $found = $false
                foreach ($scope in $scopeNames) {
                    # If match is section_scope, extract only section
                    if ($raw -like "*_$scope") {
                        $sectionName = $raw.Substring(0, $raw.Length - $scope.Length - 1)
                        # Write-Host $raw
                        # Write-Host $sectionName
                        # $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                        if ($fileSectionNames.Add($sectionName)){
                            LogAdd "adding [section_scope] $sectionName" ([ref]$logs)
                            $count = $count + 1
                            $found = $true
                        }else{
                            # LogDup "duplicate $sectionName" ([ref]$logs)
                        }
                        break
                    }
                }
                if (!$found){
                    # If it's a standalone section like [sectionName] or ![sectionName]
                    if ($modlistWeaponNames -contains $raw) {
                        # Log "standalone found: $raw" ([ref]$logs)
                        if ($fileSectionNames.Add($raw)){
                            LogAdd ">> adding [standalone] $raw" ([ref]$logs)
                            $count = $count + 1
                        }else{
                            # LogDup "duplicate $raw" ([ref]$logs)
                        }
                    } 
                }
            }       
        }

        if ($count -eq 0){
            Log "no matches in $($_.FullName)" ([ref]$logs)
            $noMatchesList += "$($_.FullName)`r`n"
            Copy-Item -Path $_.FullName -Destination "$noMatchesFilesPath\$($_.Name)"
        }else{
            $logFileName = [System.IO.Path]::ChangeExtension($_, "log")
            $fileSectionNames | Set-Content -Path "$hitPath\$logFileName"
            $fileSectionNames.GetEnumerator() | ForEach-Object { $sectionNames.Add($_) | Out-Null}
            Copy-Item -Path $_.FullName -Destination "$hitPathFilesPath\$($_.Name)"
        }     
    }

    $sectionNames = ($sectionNames + $manualEntries) | Sort-Object -Unique 

    # Save unique section names to the output file (append after header)
    $sectionNames | Add-Content -Path $outputFile

    # Sort the content of the output file (excluding the header)
    $lines = Get-Content $outputFile
    $headerLine = $lines[0]
    $sortedLines = $lines[1..($lines.Count - 1)] | Sort-Object
    $headerLine | Set-Content $outputFile
    $sortedLines | Add-Content $outputFile

    $noMatchesList | Set-Content -Path $noMatchesPath

    # write to log file
    Set-Content -Path $logpath -Value $logs

    Write-Host " Done! Unique section names saved to $outputFile"

    Write-Host " Done! Logged console output to $logpath in MO2 overwrite folder"
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
                Write-Host "Renamed: $($file.Name) -> $newName"
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
if ($update.IsPresent -and -not($3dss.IsPresent)) {
    Write-Host " Warning!! you are generating with UPDATE intent"
    Write-Host " Close window or continue"

    Write-Host
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');    

    $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
    GenerateModlistGroupFile $name $excludeWeaponNames $outputFile $from
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

# generate
if ($generate.IsPresent -and -not($3dss.IsPresent)) {
    $outputFile = ".\generation\output\seals_group_$name.ltx"
    GenerateModlistGroupFile $name $excludeWeaponNames $outputFile $from
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

# new
if($new.IsPresent){
    CreateSealsTemplateProject

    if (($null -ne $from) -and ("" -ne $from)){

        $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
        GenerateModlistGroupFile $name $excludeWeaponNames $outputFile $from
    }
}

# new
if($add.IsPresent){
    
    if (($null -ne $from) -and ("" -ne $from)){

        $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
        AddModlistGroupFile $name $outputFile $from
    }
}

# 3dss

if($3dss.IsPresent){


    if ($update.IsPresent) {
        Write-Host " Warning!! you are generating 3DSS with UPDATE intent"
        Write-Host " Close window or continue"

        Write-Host
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');   
    }


    if (($null -ne $name) -and ("" -ne $name)){
        $3dss_tag = "$($name)_3dss"
    }else{
        $3dss_tag = "3dss"
    }

    $excludeWeaponNames = @()
    $profileGroupFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_profile.ltx"
    # create a temporary profile group list which the 3dss generation will use to match section names, as reference
    GenerateModlistGroupFile "profile" $excludeWeaponNames $profileGroupFile $null

    # adds anomaly group list (ltx are in xray archives thus cannot be found in vfs)
    # adds profile (what's in vfs) group list
    $modlistGroup = "anomaly,profile"
    
    $modlistGroupNames = $modlistGroup -split ','

    foreach( $groupName in $modlistGroupNames){
        $sectionList = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_$groupName.ltx"
        $modlistWeaponNames = ($excludeWeaponNames + $sectionList) | Sort-Object -Unique 
    }

    if ($update.IsPresent) {

        $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$3dss_tag.ltx"
        Generate3DSSGroupFile $modlistWeaponNames $outputFile $from
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }

    if ($generate.IsPresent) {
        $outputFile = ".\generation\output\seals_group_$3dss_tag.ltx"
        Generate3DSSGroupFile $modlistWeaponNames $outputFile $from
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }

    Remove-Item -Path $profileGroupFile
}
