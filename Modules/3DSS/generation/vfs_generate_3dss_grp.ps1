param (
    [string]$param
)

if ($param) {
    Write-Host " Warning!! you are generating with $param intent"
    Write-Host " Close window or continue"

    Write-Host
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');    
}


if ($param -eq "update"){
    $outputFile = ".\gamedata\configs\custom_seal_layers\groups\seals_group_3dss.ltx"
}else{
    $outputFile = ".\generation\output\seals_group_3dss.ltx"
}

# Clear previous output if exists
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# logfile
$logpath = ".\generation\output\vfs_generate_3dss_grp.txt"
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

# Define files to ignore
$ignoreFiles = Get-Content ".\generation\input\ignoreFiles.txt"

# The list of 3DSS scopes
$scopeNames = Get-Content ".\generation\input\scopes.txt"

$anomalyWeaponNames = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_anomaly.ltx"

$modlistWeaponNames = Get-Content ".\gamedata\configs\custom_seal_layers\groups\seals_group_modlist.ltx"

# Merge and deduplicate
$weaponNames = ($anomalyWeaponNames + $modlistWeaponNames) | Sort-Object -Unique

# group header
$header = "[3dss]"

# Write the header to the output file first
Set-Content -Path $outputFile -Value $header

# Store matches in a hashset to avoid duplicates
$sectionNames = [System.Collections.Generic.HashSet[string]]::new()

# Scan each .ltx file with 3dss in its name
Get-ChildItem -Path "gamedata\configs" -Recurse -File -Filter "*3dss*.ltx" | Where-Object {
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
                if ($weaponNames -contains $raw) {
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
        $fileSectionNames | Set-Content -Path "$hitPath\$_"
        $fileSectionNames.GetEnumerator() | ForEach-Object { $sectionNames.Add($_) | Out-Null}
        Copy-Item -Path $_.FullName -Destination "$hitPathFilesPath\$($_.Name)"
    }     
}

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

Write-Host
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');