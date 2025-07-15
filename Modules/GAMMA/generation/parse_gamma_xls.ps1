# Path to your CSV file
$csvPath = ".\input\Weapons Database - 250205_weapons.csv"

# Path to output file
$outputPath = ".\output\group_gamma.ltx"

# Import the CSV
$data = Import-Csv -Path $csvPath

$header = "[gamma_seal]"

# Write the header to the output file first
Set-Content -Path $outputPath -Value $header

# Filter and extract Weapon Ids, then append to file
$data | Where-Object { $_.'Obtainable in GAMMA' -eq 'yes' } |
       Select-Object -ExpandProperty 'Weapon Id' |
       Add-Content -Path $outputPath -Encoding UTF8

# Sort the content of the output file (excluding the header)
$lines = Get-Content $outputPath
$headerLine = $lines[0]
$sortedLines = $lines[1..($lines.Count - 1)] | Sort-Object
$headerLine | Set-Content $outputPath
$sortedLines | Add-Content $outputPath

Write-Host " Done! Unique section names saved to $outputPath"

Write-Host
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

