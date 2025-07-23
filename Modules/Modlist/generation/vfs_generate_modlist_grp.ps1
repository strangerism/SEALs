param (
    [string]$param,
    [string]$mode
)

if ($param) {
    Write-Host " Warning!! you are generating with $param intent"
    Write-Host " Close window or continue"

    Write-Host
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');    
}

if ($param -eq "update"){
    $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_modlist.ltx"
}else{
    $outputFile = ".\generation\output\seals_group_modlist.ltx"
}

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


$weaponNames = @()
if ($mode -eq "exclusive"){
    $anomalyWeaponNames = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_anomaly.ltx"

    $gammaWeaponNames = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_gamma.ltx"

    # Merge and deduplicate
    $weaponNames = ($anomalyWeaponNames + $gammaWeaponNames) | Sort-Object -Unique
}




# Use a hash set for uniqueness
$weaponSet = [System.Collections.Generic.HashSet[string]]::new()
$noMatchesList = @()

# Search for files recursively with names starting with npc_loadouts
Get-ChildItem -Path "gamedata\configs" -Recurse -File | Where-Object { 
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
            if ($weaponNames -notcontains $section){
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
$header = "[default]"
$finalOutput = @($header) + ($weaponSet | Sort-Object)

# Write to file
$finalOutput | Set-Content -Path $outputFile
$noMatchesList | Set-Content -Path $noMatchesPath

Write-Host " Done! Unique section names saved to $outputFile"
Write-Host " Done! Logged all the hit to $hitPath in MO2 overwrite folder"
Write-Host " Done! Logged all the miss to $noMatchesPath in MO2 overwrite folder"

$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
