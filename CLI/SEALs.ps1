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
    [Parameter(Mandatory = $false)][string]$ListType,
    [Parameter(Mandatory = $false)][switch]$static,
    [Parameter(Mandatory = $false)][switch]$trades,
    [Parameter(Mandatory = $false)][switch]$rarity,
    [Parameter(Mandatory = $false)][switch]$refresh,
    [Parameter(Mandatory = $false)][switch]$test
    
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

# INPUT FILES

$FILE_GAMMA_NIMBLE_INCLUDES = "generation\input\nimble_includes.txt"
$FILE_SCOPES_INCLUDES =  "generation\input\scopes_includes.txt"
# TYPE
$LTX_TYPE_BASE = "TYPE_BASE"
$LTX_TYPE_LOADOUT = "TYPE_LOADOUT"
$LTX_TYPE_TRADE = "TYPE_TRADE"
$LTX_TYPE_ADDON = "TYPE_ADDON"

if ($ListType -eq ""){
    $ListType = $LTX_TYPE_BASE
}


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

function LogHead {
    param (
        [string]$entry,
        [ref]$logs
    )
    Log "" $logs
    Write-Host $entry -BackgroundColor Gray -ForegroundColor Black
    $logs.Value += $entry
}

function LogAdd {
    param (
        [string]$entry,
        [ref]$logs
    )

    Write-Host "+ $entry" -ForegroundColor Cyan
    $logs.Value += "+ $entry"
}

function LogDropped {
    param (
        [string]$entry,
        [ref]$logs
    )

    Write-Host "- $entry" -ForegroundColor Red
    $logs.Value += "- $entry"
}

function LogList {
    param (
        $title,
        $list,
        [ref]$logs
    )
    Log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $logs
    Log "+++++++++++++++  $title" $logs
    Log "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" $logs
    foreach ($entry in $list) {
        Write-Host "$entry" -ForegroundColor Cyan
        $logs.Value += "$entry"
    }
    Log "--------------------------------------------------------------------------------------------------------" $logs
    Log "" $logs
}

function LogDup {
    param (
        [string]$entry,
        [ref]$logs
    )

    Write-Host $entry -ForegroundColor Red
    $logs.Value += $entry
}

function Get-ArrayFromSet{
    param (
        [System.Collections.Generic.HashSet[string]]$set
    )
    $list = @()
    foreach ($item in $set) {
        $list += $item
    }
    return $list
}

function Get-LTXFilesFromType{
    Param(
        $name,
        $src,
        $ListType
    )    

    $LTXFiles = @()

    if ($ListType -eq $LTX_TYPE_BASE){

        $LTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                    $_.Name -like "w_*" -and
                    !($_.FullName -like '*weathers*') -and
                    !($_.FullName -like '*upgrades*') -and
                    !($_.FullName -like '*sound_layers*')
                } 
    }

    if ($ListType -eq $LTX_TYPE_LOADOUT){
        $LTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                    $_.Name -like "new_game_loadouts*" -or  
                    $_.Name -like "mod_new_game_loadouts*" -or  
                    $_.Name -like "npc_loadouts*" -or 
                    $_.Name -like "mod_npc_loadouts*" 
                }        
    }

    if ($ListType -eq $LTX_TYPE_TRADE){
        $LTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                (($_.Name -like "trade_*" -and ($_.Name -notmatch 'trade_presets.ltx')) -or  
                $_.Name -like "mod_trade_*" -or
                $_.Name -like "blackmarket_trade_*") -or
                ($_.Name -match "trade_presets.ltx" -and $name -ne "gamma")

            }        
    }

    if ($ListType -eq $LTX_TYPE_ADDON){
        $LTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                $_.Name -like "*.ltx" -and (
                $_.Name -like "*addons*" -or  
                $_.Name -like "*sights*"
                )
            }        
    }

    return $LTXFiles
}

function Get-ScopesFromLTXFile {
    param (
        [string]$FilePath
    )

    $kitsList = Get-Content "generation\input\kitsList.txt"

    $scopes = [System.Collections.Generic.HashSet[string]]::new()
    $lines = Get-Content $FilePath

    foreach ($line in $lines) {
        if ($line -match '^\s*([^\s;=\[\]!]+)\s*=\s*scope\b' -or
            $line -match '^\s*\[([^\]]+)\]:addon\b' -or
            $line -match '^\s*!\[([^\]]+)\]' -or
            $line -match '^\s*\[([^\]]+)\]') {
            
            $scope = $matches[1]
            if ($scope -notmatch '^wpn_' -and 
                !($scope -like "encyclopedia*") -and
                !($scope -like "supplies_*") -and
                -not ($kitsList -contains $scope)) {
                $scopes.Add($scope) | Out-Null
                # LogAdd $scope ([ref]$logs)
            }else{
                LogDropped $scope ([ref]$logs)
            }
        }
    }
    
    return $scopes
}

function Get-ScopesListFromLTXFiles{
    Param(
        $src
    )
    LogHead "Get-ScopesListFromLTXFiles from $src" ([ref]$logs)

    $addonFiles = Get-LTXFilesFromType $name $src $LTX_TYPE_ADDON

    $addonFiles | ForEach-Object {
        Log "Looking for scopes in $($_.FullName)" ([ref]$logs)
        # Extract scopes from the LTX file
        $scopeList = $scopeList + (Get-ScopesFromLTXFile $_.FullName)
    }

    $scopesIncludes = Get-Content $FILE_SCOPES_INCLUDES

    # Sort and deduplicate the list
    $scopeList = ($scopeList + $scopesIncludes ) | Sort-Object -Unique     

    LogList "SCOPES LIST" $scopeList ([ref]$logs) 

    # Write the sorted list to a file
    $outFile = ".\generation\output\scopes.txt"
    Set-Content -Path $outFile -Value $scopeList        

    # LOG "Updated modlist scopes list to " $outFile ([ref]$logs)

    return $scopeList
}

function PurgeScopedSections{
    Param(
        $src,
        $weaponList
    )

    LogHead "PurgeScopedSections" ([ref]$logs)

    $scopeNames = Get-ScopesListFromLTXFiles $src

    # 1. Remove all duplicates from $weaponSet where duplicates are weaponname, weaponname_scopename, weaponname_scopename_hud
    # Also filter out entries like weaponname_hud (keep only weaponname and weaponname_scopename)
    # Use $scopeNames to match scopename in $weaponSet

    $baseWeapons = @{}

    foreach ($weapon in $weaponList) {
        $matched = $false
        foreach ($scope in $scopeNames) {
            # Match weapon_scopename or weapon_scopename_hud
            if ($weapon -match "^(.*)_$scope(_hud)?$") {
                $base = $matches[1]
                # Only keep the base weapon (without scope and _hud)
                $baseWeapons[$base] = $base
                $matched = $true
                # LogDropped $weapon ([ref]$logs)
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
    $weaponList = New-Object System.Collections.Generic.List[string]
    foreach ($weapon in $baseWeapons.Values) {
        $weaponList.Add($weapon)
    }
    return $weaponList
}

function Get-WeaponsFromLTXFiles{
    Param(
        $name,
        $src,
        $excludeWeaponNames,
        $ListType
    )

    $noMatchesList = @()
    # $weaponSet = [System.Collections.Generic.HashSet[string]]::new()
    $weaponsArray = @{}
    $droppedWeaponSet = [System.Collections.Generic.HashSet[string]]::new()
    $weaponLTXFiles = Get-LTXFilesFromType $name $src $ListType
    $scopeNames = Get-ScopesListFromLTXFiles $src
    # Search for files recursively with names starting with npc_loadouts
    LogHead "Get-WeaponsFromLTXFiles" ([ref]$logs)
    $weaponLTXFiles | ForEach-Object {
        $content = Get-Content $_.FullName
        
        $fileWeaponSet = [System.Collections.Generic.HashSet[string]]::new()
        $count = 0        
        
        foreach ($line in $content) {
            
            # Find all matching wpn_ strings with the format weapon:N:N:N
            if ($line -match "^\s*[!\[]?(wpn_[a-zA-Z0-9_-]+)[\]]?\s*(?::.*|=\s*.*)?$") {
                $count = $count + 1
                # Write-Host found $matches[1]
                $weaponName = $matches[1]
                if (!($weaponName -like '*snd_shoot*') -and
                    !($weaponName -like '*snd_silenced*') -and
                    !($weaponName -like '*_sounds*') -and
                    !($weaponName -like '*wpn_addon_scope*') -and # base scope addon
                    !($weaponName -like '*wpn_addon_silencer*') -and # base silencer addon
                    # !($weaponName -like '*wpn_addon_grenade*') -and # grenade lanchers addon
                    ( !($weaponName -like '*_sk*') -or ($weaponName -like '*_sks*') ) -and   # no idea
                    !($weaponName -like '*wpn_sil*') -and  # silenced
                    ($weaponName -notmatch 'wpn_binoc_inv') -and
                    ($weaponName -notmatch "_hud$")
                    ) {
                        $matched = $false
                        foreach ($scope in $scopeNames) {
                            # Match weapon_scopename or weapon_scopename_hud
                            if ($weaponName -match "^(.*)_$scope$") {
                                $base = $matches[1]
                                if ($weaponsArray[$base]){
                                    # LogAdd "[$base] VARIANT: $weaponName"
                                    $weaponsArray[$base] += $weaponName
                                }else{
                                    $weaponsArray[$base] = @()
                                    $weaponsArray[$base] += $weaponName                                    
                                }
                                $matched = $true
                                break
                            }
                        }
                        if (-not $matched) {
                            # weaponName is the base weapon name
                            # LogAdd "BASE WEAPON: $weaponName"
                            if ($null -eq $weaponsArray[$weaponName]){
                                $weaponsArray[$weaponName] = @()
                                $weaponsArray[$weaponName] += $weaponName
                            }
                        }
                        $fileWeaponSet.Add($weaponName) | Out-Null
                        $count = $count + 1
                    }else{
                        # LogDropped $weaponName ([ref]$logs)
                        $droppedWeaponSet.Add($weaponName) | Out-Null
                    }
            }
        }
        if ($count -eq 0){
            Log "no matches in $($_.FullName)" ([ref]$logs)
            # add the file to the no matches files list
            $noMatchesList += $_.FullName
            # save the input scanned file
            Copy-Item -Path $_.FullName -Destination "$noMatchesFilesPath\$($_.Name)"
        }else{
            # save the hit reports to dedicated file
            $logFileName = [System.IO.Path]::ChangeExtension($_, "log")
            $fileWeaponSet | Set-Content -Path "$hitPath\$logFileName"
            # save the input scanned file
            Copy-Item -Path $_.FullName -Destination "$hitPathFilesPath\$($_.Name)"
        }
    }
    $noMatchesList | Set-Content -Path $noMatchesPath
    # LogList "SECTIONS Ignored" (Get-ArrayFromSet $droppedWeaponSet) ([ref]$logs)
    return $weaponsArray
}

function addCustomIncludes{
    Param(
        [ref]$list,
        $includeFile
    )

    $nimbleIncludes = Get-Content $includeFile

    return $list.Value + $nimbleIncludes
}

function addTreasuresIncludes{
    Param(
        [ref]$list,
        $name
    )

    if ($name -eq "anomaly"){
        $list.Value + "wpn_gauss_quest"
    }
}

function GetKitGroups{
    Param(
        $name,
        $weaponSet
    )    

    $src = "gamedata\configs"

    $weaponKitsSet = [System.Collections.Generic.HashSet[string]]::new()

    $anomalyList = @()

    if ($name -ne "anomaly"){
        # start preloading $weaponKitsSet with the anomaly list
        $anomalyList = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_anomaly.ltx"
        foreach ($kit in $anomalyList) {
            $weaponKitsSet.Add($kit) | Out-Null
        }
    } 

    $weaponLTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                        $_.Name -like "w_*"
                    }
    $weaponLTXFiles | ForEach-Object {
        $content = Get-Content $_.FullName
        foreach ($line in $content) {
            # Find all matching wpn_ strings with the format weapon:N:N:N
            if ($line -match "^\s*[!\[]?(wpn_[a-zA-Z0-9_]+)[\]]?\s*(?::.*|=\s*.*)?$") {
                # Write-Host found $matches[1]
                $weaponName = $matches[1]
                if (!($weaponName -like '*snd_shoot*') -and
                    !($weaponName -like '*snd_silenced*') -and
                    !($weaponName -like '*_sounds*') -and
                    !($weaponName -like '*wpn_addon_scope*') -and # base scope addon
                    !($weaponName -like '*wpn_addon_silencer*') -and # base silencer addon
                    !($weaponName -like '*wpn_addon_grenade*') -and # grenade lanchers addon
                    !($weaponName -like '*_sk*') -and   # no idea
                    !($weaponName -like '*wpn_sil*') -and  # silenced
                    ($weaponName -notmatch 'wpn_binoc_inv')) {
                    if ($weaponSet){
                        if($weaponSet -contains $weaponName){
                            $weaponKitsSet.Add($weaponName) | Out-Null
                        }
                    }else{
                        $weaponKitsSet.Add($weaponName) | Out-Null
                    }
                }
            }
        }
    }
    $baseWeapons = @{}

    $scopeNames = Get-Content "generation\input\scopes\scopes.txt"

    foreach ($weapon in $weaponKitsSet) {
        $matched = $false
        foreach ($scope in $scopeNames) {
            # Match weapon_scopename or weapon_scopename_hud
            if ($weapon -match "^(.*)_$scope(_hud)?$") {
                # Write-Host found $matches[1]
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
                # Write-Host found $weapon
                $baseWeapons[$weapon] = $weapon
            }
        }
    }

    $kitsList = Get-Content "generation\input\kitsList.txt"
    $kitArray = @()

    foreach ($w in $baseWeapons.Values) {
        foreach ($kit in $kitsList) {
            if ($w -like "*$kit") {
                Write-Host "kit--> $w"
                $kitArray += $w
            }
        }
    }
    return $kitArray
}

function AddModlistGroupFile{
    Param(
        $name,
        $src,
        $ListType,
        $outputFile
    )

    $excludeWeaponNames = @()
    $addOutputFile = ".\generation\output\$name\add.ltx"
    GenerateModlistGroupFile $name $src $ListType $excludeWeaponNames $addOutputFile
    $addSections = Get-Content $addOutputFile

    LogList "ADDED SECTIONS" $addSections ([ref]$logs)

    $nameSections = Get-Content $outputFile   

    $finalOutput = ($nameSections + $addSections) | Sort-Object -Unique 

    # Save unique section names to the output file
    $finalOutput | Set-Content -Path $outputFile
}

function GenerateModlistGroupFile{
    Param(
        $name,
        $src,
        $ListType,
        $excludeWeaponNames,
        $outputFile
    )

    

    if ($name -eq "gamma" -and $ListType -eq $LTX_TYPE_LOADOUT){
        $weaponsArray = Get-WeaponsFromLTXFiles $name $src $excludeWeaponNames $ListType
        # $weaponsLoadoutList = Get-WeaponsFromLTXFiles $name $src $excludeWeaponNames $LTX_TYPE_LOADOUT

        addCustomIncludes $weaponsList $FILE_GAMMA_NIMBLE_INCLUDES
        addTreasuresIncludes $weaponsList $name
    }else{
        $weaponsArray = Get-WeaponsFromLTXFiles $name $src $excludeWeaponNames $ListType
    }

    $weaponsList = New-Object System.Collections.Generic.List[string]
    foreach ($baseWeapon in $weaponsArray.Keys) {
        if ($excludeWeaponNames -notcontains $baseWeapon){
            foreach ($item in $weaponsArray[$baseWeapon]) {
                $weaponsList.Add($item)
            }
        }
    }

    $header = "[$name]"
    $finalOutput = @($header) + ($weaponsList | Sort-Object -Unique)
    # Write to file v
    $finalOutput | Set-Content -Path $outputFile
    LOG " Done! sections group file saved to $outputFile" ([ref]$logs)
}

function GenerateModlistGroupFileOld{
    Param(
        $name,
        $excludeWeaponNames,
        $outputFile,
        $modName,
        $static,
        $trades
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

    # Extract scopes from the LTX file
    $scopeList = Get-Content "generation\input\scopes\scopes.txt"

    $3dssScopeList = Get-Content "generation\input\scopes\scopes_3dss.txt"

    # Sort and deduplicate the list
    $scopeNames = ( $scopeList + $3dssScopeList ) | Sort-Object -Unique

    if ($static){

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

    if($trades){
        $tradeWeaponsLTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                (($_.Name -like "trade_*" -and ($_.Name -notmatch 'trade_presets.ltx')) -or  
                $_.Name -like "mod_trade_*" -or
                $_.Name -like "blackmarket_trade_*") -or
                ($_.Name -match "trade_presets.ltx" -and $name -ne "gamma")

            }   
        $weaponLTXFiles = $weaponLTXFiles + $tradeWeaponsLTXFiles
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
                    !($weaponName -like '*_sounds*') -and
                    !($weaponName -like '*wpn_addon_scope*') -and # base scope addon
                    !($weaponName -like '*wpn_addon_silencer*') -and # base silencer addon
                    !($weaponName -like '*wpn_addon_grenade*') -and # grenade lanchers addon
                    !($weaponName -like '*_sk*') -and   # no idea
                    !($weaponName -like '*wpn_sil*') -and  # silenced
                    ($weaponName -notmatch 'wpn_binoc_inv')) {
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

    # # 1. Remove all duplicates from $weaponSet where duplicates are weaponname, weaponname_scopename, weaponname_scopename_hud
    # # Also filter out entries like weaponname_hud (keep only weaponname and weaponname_scopename)
    # # Use $scopeNames to match scopename in $weaponSet

    # $baseWeapons = @{}

    # foreach ($weapon in $weaponSet) {
    #     $matched = $false
    #     foreach ($scope in $scopeNames) {
    #         # Match weapon_scopename or weapon_scopename_hud
    #         if ($weapon -match "^(.*)_$scope(_hud)?$") {
    #             $base = $matches[1]
    #             # Only keep the base weapon (without scope and _hud)
    #             $baseWeapons[$base] = $base
    #             $matched = $true
    #             break
    #         }
    #     }
    #     if (-not $matched) {
    #         # Write-Host $weapon
    #         # Filter out entries ending with _hud (but not matching any scope)
    #         if ($weapon -notmatch "_hud$") {
    #             $baseWeapons[$weapon] = $weapon
    #         }
    #     }
    # }

    # # Replace $weaponSet with only the purged, unique base entries
    # $weaponSet = [System.Collections.Generic.HashSet[string]]::new()
    # foreach ($w in $baseWeapons.Values) {
    #     $weaponSet.Add($w) | Out-Null
    # }   

    # # 2. add nimble trades if group is gamma
    # if ($name -eq "gamma"){
    #     $nimbleIncludes = Get-Content "generation\input\nimble_includes.txt"

    #     $weaponSet = $weaponSet + $nimbleIncludes
    # }

    # # 3. add weapon kits    
    # $kits = GetKitGroups $name $weaponSet
    # Write-Host ----- KITS ADDED
    # $kits
    # Write-Host -----

    # 4. Add header and sort
    $header = "[$name]"
    $finalOutput = @($header) + (($weaponSet + $kits)| Sort-Object -Unique)

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
    $3ddsIncludes = Get-Content ".\generation\input\3dss_includes.txt"

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

    $sectionNames = ($sectionNames + $3ddsIncludes) | Sort-Object -Unique 

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
        $name
    )

    # Output file path
    $outDir = "generation\output\$name"
    $src = "$outDir\hit\files"

    if ( -not (Test-Path $outDir) -or -not (Test-Path $src)){
        Write-Host "Cannot generate rarity lists, missing generation output. Run generate group list first"
        return
    }

    $outGrouped = "$outDir\weapons_grouped_by_chance.ltx"
    $outCsv = "$outDir\weapons_chances.csv"

    # Get all files matching the pattern
    $files = Get-ChildItem -Path $src -Filter "npc_loadouts_*.ltx"

    # For .ltx output: chance -> set of weapons (all loot tables combined)
    $weaponsByChance = @{}
    # For CSV: weapon -> loot_table_id -> highest chance
    $weaponLootTableChances = @{}

    foreach ($file in $files) {
        # Extract loot_table_id from filename
        if ($file.Name -match '^npc_loadouts_(.+)\.ltx$') {
            $loot_table_id = $Matches[1]
        } else {
            continue
        }

        $lines = Get-Content $file.FullName | Where-Object {
            $_ -and ($_ -notmatch '^\s*;') -and ($_ -match '^\s*(wpn_[^:]+):')
        }
        foreach ($line in $lines) {
            $parts = $line -split ':'
            if ($parts.Count -ge 4) {
                $weapon = $parts[0]
                $chance = [int]$parts[3]

                # For .ltx output: group by chance
                if (-not $weaponsByChance.ContainsKey($chance)) {
                    $weaponsByChance[$chance] = @()
                }
                if ($weaponsByChance[$chance] -notcontains $weapon) {
                    $weaponsByChance[$chance] += $weapon
                }

                # For CSV: keep only highest chance per loot_table_id
                if (-not $weaponLootTableChances.ContainsKey($weapon)) {
                    $weaponLootTableChances[$weapon] = @{}
                }
                if (-not $weaponLootTableChances[$weapon].ContainsKey($loot_table_id)) {
                    $weaponLootTableChances[$weapon][$loot_table_id] = $chance
                } elseif ($chance -gt $weaponLootTableChances[$weapon][$loot_table_id]) {
                    $weaponLootTableChances[$weapon][$loot_table_id] = $chance
                }
            }
        }
    }

    # Output grouped by chance (.ltx)
    $output = @()
    foreach ($chance in ($weaponsByChance.Keys | Sort-Object -Descending)) {
        $output += "[$chance]"
        $output += $weaponsByChance[$chance] | Sort-Object
        $output += ""
    }
    $output | Set-Content $outGrouped -Encoding UTF8

    # Output CSV: weapon,"chance (loot_table_id), chance (loot_table_id), ..."
    $csv = @()
    foreach ($weapon in $weaponLootTableChances.Keys | Sort-Object) {
        $pairs = @()
        foreach ($loot_table_id in $weaponLootTableChances[$weapon].Keys) {
            $chance = $weaponLootTableChances[$weapon][$loot_table_id]
            $pairs += "$chance ($loot_table_id)"
        }
        # Sort pairs by chance descending
        $pairs = $pairs | Sort-Object { [int]($_ -split ' ')[0] } -Descending
        $csv += [PSCustomObject]@{
            Weapon = $weapon
            Chances = ($pairs -join ", ")
        }
    }
    $csv | Export-Csv -Path $outCsv -NoTypeInformation -Encoding UTF8

    Write-Host "Done! Grouped output: $outGrouped"
    Write-Host "Done! CSV output: $outCsv"
}

#################################################################################################################
##############
##############                              MAIN
##############
#################################################################################################################

## LOGGING

if ($name -and $name -ne ""){
    $logfolder = $name
}else{
    $logfolder = "default" 
}

# Path to miss report and files
$noMatchesPath = ".\generation\output\$logfolder\miss\no_matches.log"
$noMatchesFilesPath = ".\generation\output\$logfolder\miss\files"
if (Test-Path $noMatchesFilesPath) {
    Remove-Item $noMatchesFilesPath -Recurse
}
New-Item -Path $noMatchesFilesPath -ItemType Directory | Out-Null

# Path to hit report and files
$hitPath = ".\generation\output\$logfolder\hit\"
$hitPathFilesPath = ".\generation\output\$logfolder\hit\files"
if (Test-Path $hitPathFilesPath) {
    Remove-Item $hitPathFilesPath -Recurse
}
New-Item -Path $hitPathFilesPath -ItemType Directory | Out-Null

#################################################################

## handling exclude

$excludeWeaponNames = @()
if ($exclude.IsPresent){

    $groupNames = $groups -split ','

    foreach( $groupName in $groupNames){
        $sectionList = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_$groupName.ltx"
        $excludeWeaponNames = ($excludeWeaponNames + $sectionList) | Sort-Object -Unique 
        $excludeWeaponNames = PurgeScopedSections $src $excludeWeaponNames
    }
}

#################################################################

## resolve src

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

#################################################################

if($test.IsPresent){

    try {
        $weaponList = Get-WeaponsFromLTXFiles $name $src $excludeWeaponNames

        LogList "WEAPONS LIST" $weaponList ([ref]$logs)

        # write to log file
        Set-Content -Path $logpath -Value $logs

        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        exit        
    }
    catch {
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }
}


if($rarity.IsPresent){

    GenerateWeaponRarityList $name 
    exit
}


# update
if ($update.IsPresent -and -not($3dss.IsPresent)) {
    Write-Host " Warning!! you are generating with UPDATE intent"
    Write-Host " Close window or continue"

    Write-Host
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');    

    $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
    GenerateModlistGroupFile $name $src $ListType $excludeWeaponNames $outputFile
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

# generate
if ($generate.IsPresent -and -not($3dss.IsPresent)) {
    $outputFile = ".\generation\output\seals_group_$name.ltx"
    GenerateModlistGroupFile $name $src $ListType $excludeWeaponNames $outputFile
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
        GenerateModlistGroupFile $name $src $ListType $excludeWeaponNames $outputFile
    }
}

# new
if($add.IsPresent){
    
    if (($null -ne $from) -and ("" -ne $from)){

        $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
        AddModlistGroupFile $name $src $ListType $outputFile
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

