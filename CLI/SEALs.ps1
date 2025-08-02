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
    [Parameter(Mandatory = $false)][switch]$rarity,
    [Parameter(Mandatory = $false)][switch]$nocache,
    [Parameter(Mandatory = $false)][switch]$test
    
)

Write-Host new $new
Write-Host add $add
Write-Host clear $clear
Write-Host generate $generate
Write-Host update $update
Write-Host 3dss $3dss
Write-Host name $name
Write-Host from $from
Write-Host exclude $exclude
Write-Host groups $groups
Write-Host ListType $ListType
Write-Host rarity $rarity
Write-Host nocache $nocache
Write-Host

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
    LogHead "Get-LTXFilesFromType $name $ListType" ([ref]$logs)
    $LTXFiles = @()

    if ($ListType -eq $LTX_TYPE_BASE){

        $LTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                    $_.Name -like "w_*" -and
                    !($_.FullName -like '*weathers*') -and
                    !($_.FullName -like '*upgrades*') -and
                    !($_.FullName -like '*sound_layers*')
                } 
    }

    if ($ListType -eq $LTX_TYPE_MOD){

        $ignoreFiles = Get-Content "$generationInputPath\input\ignoreMods.txt"

        $LTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                    $_.Name -like "mod_system_*" -and
                    !($_.Name -like "mod_system_weapon_addons*") -and
                    $ignoreFiles -notcontains $_.Name
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

        if ($name -eq "3dss"){
            $LTXFiles = Get-ChildItem -Path "gamedata\configs\mod_system_3dss_gamma_scopes.ltx"
        }else{
            $LTXFiles = Get-ChildItem -Path $src -Recurse -File | Where-Object { 
                    $_.Name -like "*.ltx" -and (
                    $_.Name -like "*addons*" -or  
                    $_.Name -like "*sights*"
                    )
                }               
        }
    }

    if ($ListType -eq $LTX_TYPE_3DSS){

        # Define files to ignore
        $ignoreFiles = Get-Content "$generationInputPath\input\ignore3DSSFiles.txt"

        $LTXFiles = Get-ChildItem -Path $src -Recurse -File -Filter "*3dss*.ltx" | Where-Object {
            $ignoreFiles -notcontains $_.Name
        }        
    }    

    if ($ListType -eq $LTX_TYPE_TREASURE){

        $gammaTreasureFile = "gamedata\configs\items\settings\grok_treasure_manager.ltx"
        if (Test-Path $gammaTreasureFile){
            $treasureFile = "grok_treasure_manager.ltx"
        }else{
            $treasureFile = "treasure_manager.ltx"
        }
        $LTXFiles = Get-ChildItem -Path "gamedata\configs\items\settings" | Where-Object {
            $_.Name -match "$treasureFile"
        }        
    }     

    return $LTXFiles
}

function Get-ScopesFromLTXFile {
    param (
        [string]$FilePath
    )

    # $kitsList = Get-Content "generation\input\kitsList.txt"

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
                !($scope -like "supplies_*")
                # -not ($kitsList -contains $scope)
                ) {
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
        $name,
        $src
    )

    # Write the sorted list to a file
    if ($name -eq "3dss"){
        $outFile = "$generationPath\output\scopes\scopes_3dss.txt"
    }else{
        $outFile = "$generationPath\output\scopes\scopes.txt"
    }

    # CACHE
    if ( !$nocache.IsPresent -and (Test-Path $outFile) ){
        return Get-Content $outFile
    }

    LogHead "Get-ScopesListFromLTXFiles from $src" ([ref]$logs)

    $addonFiles = Get-LTXFilesFromType $name $src $LTX_TYPE_ADDON

    $addonFiles | ForEach-Object {
        Log "Looking for scopes in $($_.FullName)" ([ref]$logs)
        # Extract scopes from the LTX file
        $scopeList = $scopeList + (Get-ScopesFromLTXFile $_.FullName)
    }

    if (!(Test-Path $FILE_SCOPES_INCLUDES)){
        $FILE_SCOPES_INCLUDES = "..\$CLI_FOLDER\$FILE_SCOPES_INCLUDES"
    }

    $scopesIncludes = Get-Content $FILE_SCOPES_INCLUDES

    # Sort and deduplicate the list
    $scopeList = ($scopeList + $scopesIncludes ) | Sort-Object -Unique     

    LogList "SCOPES LIST" $scopeList ([ref]$logs) 


    Set-Content -Path $outFile -Value $scopeList        

    # LOG "Updated modlist scopes list to " $outFile ([ref]$logs)

    return $scopeList
}

function PurgeScopedSections{
    Param(
        $name,
        $src,
        $weaponList
    )

    LogHead "PurgeScopedSections" ([ref]$logs)

    $scopeNames = Get-ScopesListFromLTXFiles $name $src

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

function Get-3DSSConfigsFromLTXFiles{
    Param(
        $name,
        $src,
        $ListType        
    )    
    LogHead "Get-WeaponsFromLTXFiles" ([ref]$logs)
    $noMatchesList = @()
    $3dssConfigsArray = @{}
    $droppedWeaponSet = [System.Collections.Generic.HashSet[string]]::new()
    
    # The list of 3DSS scopes
    $scopeNames = Get-ScopesListFromLTXFiles $name $src

    # the list of manually entered sections. When the generation fails, you can fall back to this file and add what is being missed
    # $3ddsIncludes = Get-Content "$generationInputPath\input\3dss_includes.txt"

    $3dssLTXFiles = Get-LTXFilesFromType $name $src $ListType

    $3dssLTXFiles | ForEach-Object {
            $content = Get-Content $_.FullName
            # LOG "Scanning for 3DSS: $($_.Name)" ([ref]$logs)
            $fileSectionNames = [System.Collections.Generic.HashSet[string]]::new()
            $count = 0
            
            foreach ($line in $content) {
                # Ignore comment lines
                if ($line.Trim() -like ";*") { continue }
                # Match all section formats: [name], ![name]
                if ($line -match '^\s*!?\[([^\]]+)\]:?.*$') {
                    $sectionName = $matches[1]
                    # Log "match: $sectionName" ([ref]$logs)
                    if ($sectionName -notmatch "_hud$"){
                        $count = $count + 1 
                        $matched = $false
                        foreach ($scope in $scopeNames) {
                            # If match is section_scope, extract only section
                            if ($sectionName -match "^(.*)_$scope$") {
                                $base = $matches[1]
                                if ($3dssConfigsArray[$base]){
                                    # LogAdd "   $sectionName" ([ref]$logs)
                                    $3dssConfigsArray[$base] += $sectionName
                                }else{
                                    # LogAdd "$base" ([ref]$logs)
                                    $3dssConfigsArray[$base] = @()
                                    $3dssConfigsArray[$base] += $base
                                    $3dssConfigsArray[$base] += $sectionName                                    
                                }
                                $matched = $true
                                break
                            }
                        }
                        if (-not $matched) {
                            # weaponName is the base weapon name
                            # LogAdd "NO 3DSS: $sectionName" ([ref]$logs)
                        }
                        $fileSectionNames.Add($sectionName) | Out-Null
                        $count = $count + 1           
                    }else{
                        # LogDropped $sectionName ([ref]$logs)
                        $droppedWeaponSet.Add($sectionName) | Out-Null
                    }   
                }else{
                    # LogDropped "no match: $line" ([ref]$logs)
                }
            }
            if ($count -eq 0){
                # Log "no matches in $($_.Name)" ([ref]$logs)
                $noMatchesList += "$($_.FullName)`r`n"
                Copy-Item -Path $_.FullName -Destination "$noMatchesFilesPath\$($_.Name)"
            }else{
                $logFileName = [System.IO.Path]::ChangeExtension($_, "log")
                $fileSectionNames | Set-Content -Path "$hitPath\$logFileName"
                Copy-Item -Path $_.FullName -Destination "$hitPathFilesPath\$($_.Name)"
            }              
    }
    $noMatchesList | Set-Content -Path $noMatchesPath 
    # LogList "SECTIONS Ignored" (Get-ArrayFromSet $droppedWeaponSet) ([ref]$logs)
    return $3dssConfigsArray
}

function Get-WeaponsFromLTXFiles{
    Param(
        $name,
        $src,
        $ListType
    )

    $noMatchesList = @()
    $weaponsArray = @{}
    $droppedWeaponSet = [System.Collections.Generic.HashSet[string]]::new()
    $weaponLTXFiles = Get-LTXFilesFromType $name $src $ListType
    $scopeNames = Get-ScopesListFromLTXFiles $name $src
    # Search for files recursively with names starting with npc_loadouts
    LogHead "Get-WeaponsFromLTXFiles" ([ref]$logs)
    $weaponLTXFiles | ForEach-Object {
        $content = Get-Content $_.FullName
        # if ($ListType -eq $LTX_TYPE_TREASURE){
        # LOG "Scanning for Weapons: $($_.Name)" ([ref]$logs)
        # }
        $fileWeaponSet = [System.Collections.Generic.HashSet[string]]::new()
        $count = 0        
        
        if ($ListType -eq $LTX_TYPE_MOD){
            $regexstr = '^\s*\[([^\]]+)\]:?.*$'

        }if ($ListType -eq $LTX_TYPE_TREASURE){
            $regexstr = '\b(wpn_[\w]+)(?=\s|$)'
        }else{
            $regexstr = "^\s*[!\[]?(wpn_[a-zA-Z0-9_-]+)[\]]?\s*(?::.*|=\s*.*)?$"
        }

        foreach ($line in $content) {
            
            if ($line.Trim() -like ";*") { continue }

            # Find all matching wpn_ strings with the format weapon:N:N:N
            if ($line -match $regexstr) {

                $weaponName = $matches[1]
                # if ($ListType -eq $LTX_TYPE_TREASURE){
                #     Write-Host found $matches[1]
                # }                

                if (!($weaponName -like '*snd_shoot*') -and
                    !($weaponName -like '*shoot_actor*') -and
                    !($weaponName -like '*silncer_shot*') -and
                    !($weaponName -like '*silenced_actor*') -and
                    !($weaponName -like '*snd_silencer_shot*') -and
                    !($weaponName -like '*silenced*') -and
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
                                    # if ($ListType -eq $LTX_TYPE_TREASURE){
                                    # LogAdd "[$base] VARIANT: $weaponName" ([ref]$logs)
                                    # }
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
                            # if ($ListType -eq $LTX_TYPE_TREASURE){
                            # LogAdd "BASE WEAPON: $weaponName" ([ref]$logs)
                            # }
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
            # Log "no matches in $($_.Name)" ([ref]$logs)
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
        $list,
        $includeFile
    )

    $includes = Get-Content $includeFile
    return ($list + $includes)
}

function addTreasuresIncludes{
    Param(
        $list,
        $name
    )

    $list = $list + "wpn_gauss_quest"

    if ($name -eq "anomaly"){
        
    }
    if ($name -eq "gamma"){

    }

    return $list
}

function ConvertToList{
    Param(
        $array
    )   
    
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($key in $array.Keys) {
        foreach ($item in $array[$key]) {
            $list.Add($item)
        }
    }

    # Remove duplicates and sort
    $unique = $list | Get-Unique
    return $unique

}

function MergeArrays{
    Param(
        $kvList1,
        $kvList2
    )  


    $mergedKvList = @{}

    # Add all keys from the first hashtable
    foreach ($key in $kvList1.Keys) {
        $mergedKvList[$key] = $kvList1[$key]
    }

    # Merge in the second hashtable
    foreach ($key in $kvList2.Keys) {
        if ($mergedKvList.ContainsKey($key)) {
            $mergedKvList[$key] += $kvList2[$key]
        } else {
            $mergedKvList[$key] = $kvList2[$key]
        }
    }

    return $mergedKvList
}

function AddModlistGroupFile{
    Param(
        $name,
        $src,
        $ListType,
        $excludeWeaponNames,
        $outputFile
    )

    $addOutputFile = "$generationPath\output\$name\add.ltx"
    GenerateModlistGroupFile $name $src $ListType $addOutputFile
    $addSections = Get-Content $addOutputFile

    LogList "ADDED SECTIONS" $addSections ([ref]$logs)

    $nameSections = Get-Content $outputFile   

    $finalOutput = ($nameSections + $addSections) | Sort-Object -Unique 

    # Save unique section names to the output file
    $finalOutput | Set-Content -Path $outputFile
}

function GenerateLoadoutGroupFile{
    Param(
        $name,
        $src,
        $excludeWeaponNames
    )    

    LOG " GENERATING $name LOADOUT GROUP LIST" ([ref]$logs)

    $weaponsArray = Get-WeaponsFromLTXFiles $name $src $LTX_TYPE_BASE
    $weaponsArray.Keys | Sort-Object | Out-File -FilePath "$generationPath\output\$logfolder\weaponsBaseList.log"

    $modWeaponsArray = Get-WeaponsFromLTXFiles $name $src $LTX_TYPE_MOD
    $modWeaponsArray.Keys | Sort-Object | Out-File -FilePath "$generationPath\output\$logfolder\weaponsModsList.log"
    
    $mergedWeaponsArray = MergeArrays $weaponsArray $modWeaponsArray
    $mergedWeaponsArray.Keys | Sort-Object | Out-File -FilePath "$generationPath\output\$logfolder\mergedWeaponsList.log"

    ## filter out all weapons (base and its variants) that are not in the loadout list
    $weaponsLoadoutArray = Get-WeaponsFromLTXFiles $name $src $LTX_TYPE_LOADOUT
    $weaponsLoadoutArray.Keys | Sort-Object | Out-File -FilePath "$generationPath\output\$logfolder\weaponsLoadoutList.log"

    ## treasures rewars, akin to loadout
    $weaponsTreasureArray = Get-WeaponsFromLTXFiles $name $src $LTX_TYPE_TREASURE
    $weaponsTreasureArray.Keys | Sort-Object | Out-File -FilePath "$generationPath\output\$logfolder\weaponsTreasuresList.log"

    $weaponsLoadoutArray = MergeArrays $weaponsLoadoutArray $weaponsTreasureArray

    $weaponsLoadout = ConvertToList $weaponsLoadoutArray

    if($name -eq "gamma"){
        $weaponsLoadout = addCustomIncludes $weaponsLoadout $FILE_GAMMA_NIMBLE_INCLUDES            
    }
    
    $weaponsList = New-Object System.Collections.Generic.List[string]
    foreach ($baseWeapon in $mergedWeaponsArray.Keys) {
        # LOG " BASE WEAPON : $baseWeapon" ([ref]$logs) 
        if (($excludeWeaponNames -notcontains $baseWeapon) -and 
            ($weaponsLoadout -contains $baseWeapon) ){

                foreach ($item in $mergedWeaponsArray[$baseWeapon]) {
                    # LOG " - VARIANT : $item" ([ref]$logs) 
                    $weaponsList.Add($item)
                }
        }
    }

    $weaponsList = addTreasuresIncludes $weaponsList $name    

    return $weaponsList
}

function GenerateBaseGroupFile{
    Param(
        $name,
        $src,
        $excludeWeaponNames
    )  

    LOG " GENERATING $name BASE GROUP LIST" ([ref]$logs)
    $weaponsArray = Get-WeaponsFromLTXFiles $name $src $LTX_TYPE_BASE
    $weaponsArray.Keys | Sort-Object | Out-File -FilePath "$generationPath\output\$logfolder\weaponsBaseList.log"

    $modWeaponsArray = Get-WeaponsFromLTXFiles $name $src $LTX_TYPE_MOD
    $modWeaponsArray.Keys | Sort-Object | Out-File -FilePath "$generationPath\output\$logfolder\weaponsModsList.log"

    $weaponsArray = MergeArrays $weaponsArray $modWeaponsArray
    $weaponsArray.Keys | Sort-Object | Out-File -FilePath "$generationPath\output\$logfolder\mergedWeaponsList.log"

    $weaponsList = New-Object System.Collections.Generic.List[string]
    foreach ($baseWeapon in $weaponsArray.Keys) {
        if ($excludeWeaponNames -notcontains $baseWeapon){
            foreach ($item in $weaponsArray[$baseWeapon]) {
                $weaponsList.Add($item)
            }
        }
    }      
    
    $weaponsList = addTreasuresIncludes $weaponsList $name    

    return $weaponsList
}

function Generate3DSSGroupFile{
    Param(
        $name,
        $src,
        $excludeWeaponNames
    )  

    # generate the modlist's weapons data
    # $list = GenerateLoadoutGroupFile "profile" $src
    # $profileOutput = ".\gamedata\configs\custom_seal_layers\groups\seals_group_profile.ltx"
    # $header = "[profile]"
    # $finalOutput = @($header) + ($list | Sort-Object -Unique)
    # $finalOutput | Set-Content -Path $profileOutput

    LOG " GENERATING $name CONFIG GROUP LIST" ([ref]$logs)

    # $modlistGroup = "anomaly,profile"
    
    # $modlistGroupNames = $modlistGroup -split ','

    # foreach( $groupName in $modlistGroupNames){
    #     $sectionList = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_$groupName.ltx"
    #     $finalExcludeWeaponNames = ($excludeWeaponNames + $sectionList) | Sort-Object -Unique 
    # }        

    $3dssConfigsArray = Get-3DSSConfigsFromLTXFiles $name $src $LTX_TYPE_3DSS
    
    $list = ConvertToList $3dssConfigsArray

    return $list
}

function GenerateModlistGroupFile{
    Param(
        $name,
        $src,
        $ListType,
        $excludeWeaponNames,
        $outputFile
    )

    if($name -eq "3dss"){

        $list = Generate3DSSGroupFile $name $src $excludeWeaponNames

    }elseif ($ListType -eq $LTX_TYPE_LOADOUT){

        $list = GenerateLoadoutGroupFile $name $src $excludeWeaponNames
        
    }else{

        $list = GenerateBaseGroupFile $name $src $excludeWeaponNames
    }

    $header = "[$name]"
    $finalOutput = @($header) + ($list | Sort-Object -Unique)
    # Write to file v
    $finalOutput | Set-Content -Path $outputFile
    LOG " Done! sections group file saved to $outputFile" ([ref]$logs)
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
    $outDir = "$generationPath\output\$name"
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

# CLI FOLDER

$config = Get-Content -Path "$Env:SEALS_CLI\CLI.ini" | Where-Object { $_ -match '^CLI_FOLDER=' }
$CLI_FOLDER = $config -replace '^CLI_FOLDER=', ''
Write-Host "CLI folder is $CLI_FOLDER"
Write-Host

#################################################################

## PATHS

if ($from -ne "") {
    $src = "..\$from\gamedata\configs"
    $generationPath = "..\..\generation"
    $generationInputPath = "..\$CLI_FOLDER\generation"
    # Verify the mod exists
    if (-not (Test-Path -Path $src)) {
        Write-Error "$src does not exist."
        return
    } 
}else{
    $src = "gamedata\configs"
    $generationPath = ".\generation"
    $generationInputPath = ".\generation"
}

Write-Host src $src
Write-Host generationPath $generationPath
Write-Host generationInputPath $generationInputPath
Write-Host
## LOGGING

# logfile
$logpath = "$generationPath\output\seals.log"
$logs = @()

# log folder
if ($name -and $name -ne ""){
    $logfolder = $name
}else{
    $logfolder = "default" 
}

# Path to miss report and files
$noMatchesPath = "$generationPath\output\$logfolder\miss\no_matches.log"
$noMatchesFilesPath = "$generationPath\output\$logfolder\miss\files"
if (Test-Path $noMatchesFilesPath) {
    Remove-Item "$generationPath\output\$logfolder" -Recurse -Force
}
New-Item -Path $noMatchesFilesPath -ItemType Directory | Out-Null

# Path to hit report and files
$hitPath = "$generationPath\output\$logfolder\hit\"
$hitPathFilesPath = "$generationPath\output\$logfolder\hit\files"
if (Test-Path $hitPathFilesPath) {
    Remove-Item "$generationPath\output\$logfolder" -Recurse -Force
}
New-Item -Path $hitPathFilesPath -ItemType Directory | Out-Null


# INPUT FILES

$FILE_GAMMA_NIMBLE_INCLUDES = "$generationPath\input\nimble_includes.txt"
$FILE_SCOPES_INCLUDES =  "$generationPath\input\scopes_includes.txt"

# LIST TYPE CONSTANTS
$LTX_TYPE_BASE = "TYPE_BASE"
$LTX_TYPE_LOADOUT = "TYPE_LOADOUT"
$LTX_TYPE_TRADE = "TYPE_TRADE"
$LTX_TYPE_ADDON = "TYPE_ADDON"
$LTX_TYPE_3DSS = "TYPE_3DSS"
$LTX_TYPE_MOD = "TYPE_MOD"
$LTX_TYPE_TREASURE = "TYPE_TREASURE"

if ($ListType -eq ""){
    $ListType = $LTX_TYPE_BASE
}

#################################################################

## handling exclude

$excludeWeaponNames = @()
if ($exclude.IsPresent){

    $groupNames = $groups -split ','

    foreach( $groupName in $groupNames){
        $sectionList = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_$groupName.ltx"
        $excludeWeaponNames = ($excludeWeaponNames + $sectionList) | Sort-Object -Unique 
        $excludeWeaponNames = PurgeScopedSections $name $src $excludeWeaponNames
    }
}

#################################################################

function Completion{
    LogHead "Execution Complete" ([ref]$logs)
    Write-Host " Done! Logged console output to $logpath in MO2 overwrite folder"
    Write-Host " Done! Logged all the hit to $hitPath in MO2 overwrite folder"
    Write-Host " Done! Logged all the miss to $noMatchesPath in MO2 overwrite folder"

    # write to log file
    Set-Content -Path $logpath -Value $logs
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    exit    
}

if($test.IsPresent){

    try {
        $weaponList = Get-WeaponsFromLTXFiles $name $src $ListType

        LogList "WEAPONS LIST" $weaponList ([ref]$logs)

        Completion
    }
    catch {
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
    }
}


if($rarity.IsPresent){

    GenerateWeaponRarityList $name 
}


# update
if ($update.IsPresent) {
    Write-Host " Warning!! you are generating with UPDATE intent"
    Write-Host " Close window or continue"

    Write-Host
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');    

    $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
    GenerateModlistGroupFile $name $src $ListType $excludeWeaponNames $outputFile
    Completion
}

# generate
if ($generate.IsPresent) {
    $outputFile = "$generationPath\output\$logfolder\seals_group_$name.ltx"
    GenerateModlistGroupFile $name $src $ListType $excludeWeaponNames $outputFile
    Completion
}

if($clear.IsPresent){
    $emptyList = @()
    $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
    Set-Content $outputFile $emptyList
    Completion
}

# new
if($new.IsPresent){
    CreateSealsTemplateProject

    if (($null -ne $from) -and ("" -ne $from)){

        $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
        GenerateModlistGroupFile $name $src $ListType $excludeWeaponNames $outputFile
        Completion
    }
}

# new
if($add.IsPresent){
    
    if (($null -ne $from) -and ("" -ne $from)){

        $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_$name.ltx"
        AddModlistGroupFile $name $src $ListType $excludeWeaponNames $outputFile
        Completion
    }
}
