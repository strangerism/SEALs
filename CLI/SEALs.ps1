param (
    [Parameter(Mandatory = $false)][switch]$new,
    [Parameter(Mandatory = $false)][switch]$add,
    [Parameter(Mandatory = $false)][switch]$clear,
    [Parameter(Mandatory = $false)][switch]$generate,
    [Parameter(Mandatory = $false)][switch]$update,
    [Parameter(Mandatory = $false)][switch]$3dss,
    [Parameter(Mandatory = $false)][string]$name,
    [Parameter(Mandatory = $false)][string]$from,
    [Parameter(Mandatory = $false)][switch]$exclude,
    [Parameter(Mandatory = $false)][string]$groups,
    [Parameter(Mandatory = $false)][switch]$static,
    [Parameter(Mandatory = $false)][switch]$drops,
    [Parameter(Mandatory = $false)][switch]$refresh
    
)
Write-Host generate $new
Write-Host new $generate
Write-Host update $update
Write-Host name $name
Write-Host "from $from"
Write-Host exclude $exclude
Write-Host groups $groups

# Reads the folder filename
$config = Get-Content -Path "$Env:SEALS_CLI\CLI.ini" | Where-Object { $_ -match '^CLI_FOLDER=' }
$CLI_FOLDER = $config -replace '^CLI_FOLDER=', ''
Write-Host "CLI folder is $CLI_FOLDER"

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

function LogList {
    param (
        $list,
        [ref]$logs
    )

    foreach ($entry in $list) {
        Write-Host "$entry" -ForegroundColor Cyan
        $logs.Value += "$entry`r`n"
    }
}

function LogDup {
    param (
        [string]$entry,
        [ref]$logs
    )

    Write-Host $entry -ForegroundColor Red
    $logs.Value += $entry
}

function Get-ScopesFromLTXFile {
    param (
        [string]$FilePath
    )

    $scopes = [System.Collections.Generic.HashSet[string]]::new()
    $lines = Get-Content $FilePath

    foreach ($line in $lines) {
        # Match: name = scope
        if ($line -match '^\s*([^\s;=\[\]!]+)\s*=\s*scope\b') {
            $scope = $matches[1]
            if ($scope -notmatch '^wpn_') {
                $scopes.Add($scope) | Out-Null
            }
        }
        # Match: [name]:addon
        elseif ($line -match '^\s*\[([^\]]+)\]:addon\b') {
            $scope = $matches[1]
            if ($scope -notmatch '^wpn_') {
                $scopes.Add($scope) | Out-Null
            }
        }
        # Match: ![name]
        elseif ($line -match '^\s*!\[([^\]]+)\]') {
            $scope = $matches[1]
            if ($scope -notmatch '^wpn_') {
                $scopes.Add($scope) | Out-Null
            }
        }
        # Match: [name] (no colon, no exclamation)
        elseif ($line -match '^\s*\[([^\]]+)\]') {
            $scope = $matches[1]
            if ($scope -notmatch '^wpn_') {
                $scopes.Add($scope) | Out-Null
            }
        }
    }

    return $scopes
}

function AddModlistGroupFile{
    Param(
        $name,
        $outputFile,
        $modName,
        $static
    )

    $excludeWeaponNames = @()

    GenerateModlistGroupFile $name $excludeWeaponNames ".\generation\output\$name\add.ltx" $modName $static

    $addSections = Get-Content ".\generation\output\$name\add.ltx"

    Write-Host
    Write-Host
    LogAdd "Added sections:" ([ref]$logs)
    LogList $addSections ([ref]$logs)
    Write-Host

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
        $modName,
        $static
    )

    Write-Host name $name
    Write-Host outputFile $outputFile
    Write-Host modName $modName
    
    # Clear previous output if exists
    if (Test-Path $outputFile) {
        Remove-Item $outputFile -Force
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

    # The list of the scopes found in the modlist
    $scopeNames = @()

    if ($static){

        # Extract scopes from the LTX file
        $scopeList = Get-Content "..\$CLI_FOLDER\generation\input\scopes\scopes.txt"

        $3dssScopeList = Get-Content "..\$CLI_FOLDER\generation\input\scopes\scopes_3dss.txt"

        # Sort and deduplicate the list
        $scopeNames = ( $scopeList + $3dssScopeList ) | Sort-Object -Unique

        $weaponLTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                            $_.Name -like "w_*"
                        }
    }else{
        $weaponLTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                        $_.Name -like "new_game_loadouts*" -or  
                        $_.Name -like "mod_new_game_loadouts*" -or  
                        $_.Name -like "npc_loadouts*" -or 
                        $_.Name -like "mod_npc_loadouts*" 
                    }
    }
    # Search for files recursively with names starting with npc_loadouts
    $weaponLTXFiles | ForEach-Object {
        $content = Get-Content $_.FullName
        
        $fileWeaponSet = [System.Collections.Generic.HashSet[string]]::new()
        $count = 0        
        
        foreach ($line in $content) {
            
            # Find all matching wpn_ strings with the format weapon:N:N:N
            if ($line -match "^\s*[!\[]?(wpn_[a-zA-Z0-9_]+)[\]]?\s*(?::.*|=\s*.*)?$") {
                $count = $count + 1
                # Write-Host found $matches[1]
                $weaponName = $matches[1]
                if (!($weaponName -like '*snd_shoot*') -and
                    !($weaponName -like '*snd_silenced*') -and
                    !($weaponName -like '*_sounds*')) {
                    $fileWeaponSet.Add($weaponName) | Out-Null
                    $count = $count + 1
                }
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

    if ($static){

        # Remove all duplicates from $weaponSet where duplicates are weaponname, weaponname_scopename, weaponname_scopename_hud
        # Also filter out entries like weaponname_hud (keep only weaponname and weaponname_scopename)
        # Use $scopeNames to match scopename in $weaponSet

        $baseWeapons = @{}

        foreach ($weapon in $weaponSet) {
            $matched = $false
            foreach ($scope in $scopeNames) {
                # Match weapon_scopename or weapon_scopename_hud
                if ($weapon -match "^(.*)_$scope(_hud)?$") {
                    $base = $matches[1]
                    # Only keep the base weapon (without scope and _hud)
                    $baseWeapons[$base] = $base
                    $matched = $true
                    break
                }
            }
            if (-not $matched) {
                # Filter out entries ending with _hud (but not matching any scope)
                if ($weapon -notmatch "_hud$") {
                    $baseWeapons[$weapon] = $weapon
                }
            }
        }

        # Replace $weaponSet with only the purged, unique base entries
        $weaponSet = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($w in $baseWeapons.Values) {
            $weaponSet.Add($w) | Out-Null
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
    $ignoreFiles = Get-Content ".\generation\input\ignore3DSSFiles.txt"

    # The list of 3DSS scopes
    $scopeNames = Get-Content ".\generation\input\scopes\scopes_3dss.txt"

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

function GenerateWeaponRarityList{
    Param(
        $name,
        $excludeWeaponNames,
        $outputFile,
        $modName,
        $static
    )

    # Output file path
    $outDir = "d:\games\GAMMA\GAMMA RC3\overwrite\generation\output\$name"

    $dir = "d:\games\GAMMA\GAMMA RC3\overwrite\generation\output\gamma\hit\files"
    $outGrouped = "$outDir\weapons_grouped_by_chance.ltx"
    $outCsv = "$outDir\weapons_chances.csv"

    # Get all files matching the pattern
    $files = Get-ChildItem -Path $dir -Filter "npc_loadouts*"

    # Dictionaries for grouping
    $weaponsByChance = @{}
    $weaponChances = @{}

    foreach ($file in $files) {
        $lines = Get-Content $file.FullName | Where-Object {
            $_ -and ($_ -notmatch '^\s*;') -and ($_ -match '^wpn_')
        }
        foreach ($line in $lines) {
            $parts = $line -split ':'
            if ($parts.Count -ge 4) {
                $weapon = $parts[0]
                $chance = [int]$parts[3]

                # Group by chance
                if (-not $weaponsByChance.ContainsKey($chance)) {
                    $weaponsByChance[$chance] = @()
                }
                if ($weaponsByChance[$chance] -notcontains $weapon) {
                    $weaponsByChance[$chance] += $weapon
                }

                # Collect all chances for each weapon
                if (-not $weaponChances.ContainsKey($weapon)) {
                    $weaponChances[$weapon] = @()
                }
                if ($weaponChances[$weapon] -notcontains $chance) {
                    $weaponChances[$weapon] += $chance
                }
            }
        }
    }

    # Output grouped by chance
    $output = @()
    foreach ($chance in ($weaponsByChance.Keys | Sort-Object -Descending)) {
        $output += "[$chance]"
        $output += $weaponsByChance[$chance] | Sort-Object
        $output += ""
    }
    $output | Set-Content $outGrouped -Encoding UTF8

    # Output CSV: weapon,chances
    $csv = @()
    foreach ($weapon in $weaponChances.Keys | Sort-Object) {
        $chances = ($weaponChances[$weapon] | Sort-Object -Descending) -join ", "
        $csv += [PSCustomObject]@{
            Weapon = $weapon
            Chances = $chances
        }
    }
    $csv | Export-Csv -Path $outCsv -NoTypeInformation -Encoding UTF8

    Write-Host "Done! Grouped output: $outGrouped"
    Write-Host "Done! CSV output: $outCsv"
}
function GenerateScopesList{
    Param(
        $inputFile,
        $outFile
    ) 

    $scopeList = @()

    if ((($null -ne $inputFile) -and ("" -ne $inputFile)) -and (Test-Path $inputFile)){

        Write-Host Generating from $inputFile

        # Extract scopes from the LTX file
        $scopeList = Get-ScopesFromLTXFile $inputFile

        # Sort and deduplicate the list
        $scopeList = $scopeList | Sort-Object -Unique

        # Write the sorted list to a file
        Set-Content -Path $outFile -Value $scopeList        

        Write-Host Saved scope list to $outFile
    }else{

        $addonFiles = Get-ChildItem -Path "gamedata/configs" -Recurse -File | Where-Object { 
                $_.Name -like "*addons*" -or  
                $_.Name -like "*sights*"
            }

        $addonFiles | ForEach-Object {
            Write-Host Generating from $_.FullName
            # Extract scopes from the LTX file
            $scopeList = $scopeList + (Get-ScopesFromLTXFile $_.FullName)
        }

        # Sort and deduplicate the list
        $scopeList = $scopeList | Sort-Object -Unique

        # Write the sorted list to a file
        Set-Content -Path $outFile -Value $scopeList        

        Write-Host Saved scope list to $outFile        

    }

    return $scopeList
}


# if($scopes.IsPresent){

#     if ($3dss.IsPresent){
#         $inputFile = "generation\input\mod_system_3dss_gamma_scopes.ltx"
#         $outFile = "generation\input\scopes\scopes_3dss.txt"
#     }else{
#         $inputFile = "generation\input\weapon_addons.ltx"
#         $outFile = "generation\input\scopes\scopes.txt"
#     }

#     $scopeList = GenerateScopesList $inputFile $outFile

#     # Optional: Output to console
#     $scopeList

#     exit
# }

if($drops.IsPresent){

    GenerateWeaponRarityList $name 
    exit
}

if ($refresh.IsPresent){

    # $inputFile = "gamedata\configs\items\weapons\weapon_addons.ltx"
    $outFile = "generation\input\scopes\scopes.txt"

    GenerateScopesList -outFile $outFile

    $inputFile = "gamedata\configs\mod_system_3dss_gamma_scopes.ltx"
    $outFile = "generation\input\scopes\scopes_3dss.txt"

    GenerateScopesList $inputFile $outFile

    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    exit
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
    GenerateModlistGroupFile $name $excludeWeaponNames $outputFile $from $static
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

# generate
if ($generate.IsPresent -and -not($3dss.IsPresent)) {
    $outputFile = ".\generation\output\seals_group_$name.ltx"
    GenerateModlistGroupFile $name $excludeWeaponNames $outputFile $from $static
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

if($clear.IsPresent){
    $emptyList = @()
    $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
    Set-Content $outputFile $emptyList
}

# new
if($new.IsPresent){
    CreateSealsTemplateProject

    if (($null -ne $from) -and ("" -ne $from)){

        $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
        GenerateModlistGroupFile $name $excludeWeaponNames $outputFile $from $static
    }
}

# new
if($add.IsPresent){
    
    if (($null -ne $from) -and ("" -ne $from)){

        $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
        AddModlistGroupFile $name $outputFile $from $static
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

