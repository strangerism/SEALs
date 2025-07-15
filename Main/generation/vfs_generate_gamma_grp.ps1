param (
    [string]$param
)

Write-Host " Warning!! you are generating with $param intent"
Write-Host " Close window or continue"

Write-Host
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

if ($param -eq "update"){
    $outputFile = ".\gamedata\configs\custom_icon_layers\groups\group_gamma.ltx"
}else{
    $outputFile = ".\generation\output\group_gamma.ltx"
}

# Path to miss file
$noMatchesPath = ".\generation\output\miss\no_matches.ltx"
$hitPath = ".\generation\output\hit\"


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
    foreach ($line in $content) {
        $count = 0
        # Find all matching wpn_ strings with the format weapon:N:N:N
        if ($line -match "(wpn_[a-zA-Z0-9_]+):[a-zA-Z0-9_]+:[a-zA-Z0-9_]+(:[a-zA-Z0-9_]+)?"
) {
            $count = $count + 1
            # Write-Host found $matches[1]
            $weaponName = $matches[1]
            $weaponSet.Add($weaponName) | Out-Null
        }
    }
    if ($count -eq 0){
        Write-Host no matches in $_.FullName
        $noMatchesList += $_.FullName
    }else{
        $weaponSet | Set-Content -Path "$hitPath\$_"
    }
}

# Add header and sort
$header = "[gamma_seal]"
$finalOutput = @($header) + ($weaponSet | Sort-Object)

# Write to file
$finalOutput | Set-Content -Path $outputFile
$noMatchesList | Set-Content -Path $noMatchesPath

Write-Host "All weapons saved to $outputFile"

$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
