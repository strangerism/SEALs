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
    $outputFile = ".\gamedata\configs\custom_icon_layers\groups\group_3dss.ltx"
}else{
    $outputFile = ".\generation\output\group_3dss.ltx"
}

# Clear previous output if exists
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Paths to logging files
$noMatchesPath = ".\generation\output\miss\no_matches.ltx"
# Clear previous output if exists
if (Test-Path $noMatchesPath) {
    Remove-Item $noMatchesPath
}

$hitPath = ".\generation\output\hit"
# Clear previous output if exists
if (Test-Path $hitPath) {
    Remove-Item -Path $hitPath -Recurse
    New-Item -Path $hitPath -ItemType Directory
}

# Define files to ignore
$ignoreFiles = @(
                    "mod_system_3dss_colors.ltx", 
                    "group_3dss.ltx",
                    "mod_parts_3dss.ltx",
                    "mod_system_3dss_gamma_scopes.ltx"
                    )

$header = "[3dss_seal]"

# Write the header to the output file first
Set-Content -Path $outputFile -Value $header

# Path to the scope name file
$scopeFile = ".\generation\input\scopes.txt"
$scopeNames = Get-Content $scopeFile

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

            foreach ($scope in $scopeNames) {
                # If match is section_scope, extract only section
                if ($raw -like "*_$scope") {
                    $sectionName = $raw.Substring(0, $raw.Length - $scope.Length - 1)
                    if ($fileSectionNames.Add($sectionName)){
                        Write-Host adding $sectionName 
                        $count = $count + 1
                    }
                    break
                }
            }

            # If it's a standalone section like [sectionName] or ![sectionName]
            if ($scopeNames -notcontains $raw -and ($raw -notlike "*_*")) {
                if ($fileSectionNames.Add($raw)){
                    Write-Host adding $sectionName
                    $count = $count + 1
                }
            }  
        }       
    }

    if ($count -eq 0){
        Write-Host no matches in $_.FullName
        $noMatchesList += $_.FullName
    }else{
        $fileSectionNames | Set-Content -Path "$hitPath\$_"
        $sectionNames.Add($fileSectionNames) | Out-Null
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

Write-Host " Done! Unique section names saved to $outputFile"
Write-Host " Done! Logged all the hit to $hitPath in MO2 overwrite folder"
Write-Host " Done! Logged all the miss to $noMatchesPath in MO2 overwrite folder"

Write-Host
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');