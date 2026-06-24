$baseUser  = $env:USERPROFILE
$basePath  = Join-Path $baseUser "eleres1\eleres2\LOGS"
$logFile   = Join-Path $basePath "BACKUP_ERRORS.txt"

# Külön base minden LL-nek -> IT
$baseNC5 = Join-Path $baseUser "Box\SORNEV5\NC\Backups"
$baseNC6 = Join-Path $baseUser "Box\SORNEV6\NC\Backups"
$baseNC7 = Join-Path $baseUser "Box\SORNEV7\NC\Backups"
$baseNC8 = Join-Path $baseUser "Box\SORNEV8\NC\Backups"

# Logging 
function Write-Log {
    param(
        [string]$Uzenet,
        [string]$Szint = "INFO"
    )
    $sor = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Szint] $Uzenet"
    Write-Host $sor
    $sor | Out-File $logFile -Append -Encoding UTF8
}

# Indulás logolása
Write-Log "========================================" "INFO"
Write-Log "Futas indul" "INFO"

$lineMap = @{
    $baseNC5 = "SORNEV5"
    $baseNC6 = "SORNEV6"
    $baseNC7 = "SORNEV7"
    $baseNC8 = "SORNEV8"
}
$machines = @(


#SORNEV5
    "$baseNC5\op10_0146",
    "$baseNC5\op20_0145", 
    "$baseNC5\op30_0144", 
    "$baseNC5\op40_0122", 
    "$baseNC5\op50_0123" 

#SORNEV6
    "$baseNC6\op10_0134",
    "$baseNC6\op20_0133", 
    "$baseNC6\op30_0132", 
    "$baseNC6\op40_0135", 
    "$baseNC6\op50_0131", 
    "$baseNC6\op60_0130"
											
#SORNEV7
    "$baseNC7\op10_0124",
    "$baseNC7\op20_0125", 
    "$baseNC7\op30_0126", 
    "$baseNC7\op40_0127", 
    "$baseNC7\op50_0128", 
    "$baseNC7\op60_0129",


#SORNEV8
    "$baseNC8\op10_0152",
    "$baseNC8\op20_0151", 
    "$baseNC8\op30_0150", 
    "$baseNC8\op40_0149", 
    "$baseNC8\op50_0148", 
    "$baseNC8\op60_0147"


)

foreach ($root in $machines) {

    # 1. Legfrissebb ZIP keresés
    try {
        $latestZip =
            Get-ChildItem $root -Filter *.zip -ErrorAction Stop |
            Where-Object { $_.Name -match '^\d{8}_' } |
            ForEach-Object {
                [PSCustomObject]@{
                    File = $_
                    Date = [datetime]::ParseExact(
                        $_.Name.Substring(0,8),
                        'yyyyMMdd',
                        $null
                    )
                }
            } |
            Sort-Object Date -Descending |
            Select-Object -First 1 |
            Select-Object -ExpandProperty File
    }
    catch {
        $hiba = "Mappa nem elheto el ($root): $_"
        Write-Log $hiba "ERROR"
        continue  # következő gépre ugrik
    }

    if (-not $latestZip) {
        Write-Log "Nincs ZIP itt: $root" "WARNING"
        continue
    }

    
    $machineName = Split-Path $root -Leaf
    $parentPath  = Split-Path $root -Parent
    $lineName    = $lineMap[$parentPath]


    $zipDate = [datetime]::ParseExact($latestZip.Name.Substring(0,8), 'yyyyMMdd', $null)
    $kulonbseg = (Get-Date) - $zipDate

    # 2. Kibontás
    $tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString())
    try {
        Expand-Archive $latestZip.FullName $tmp -Force -ErrorAction Stop
    }
    catch {
        $hiba = "ZIP kibontasi hiba ($machineName - $($latestZip.Name)): $_"
        Write-Log $hiba "ERROR"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        continue  # következő gépre ugrik
    }

    $sourceFile = Get-ChildItem $tmp -Recurse -Filter CURTIME.txt -ErrorAction SilentlyContinue | Select-Object -First 1

    $outDirCUR = Join-Path $basePath "terulet\$lineName"
    New-Item -ItemType Directory -Path $outDirCUR -Force | Out-Null

    # 3. Másolás
    if ($sourceFile) {
        try {
            $fileName = "${machineName}_CURTIME.txt"
            Copy-Item $sourceFile.FullName (Join-Path $outDirCUR $fileName) -Force -ErrorAction Stop
        }
        catch {
            $hiba = "Masolasi hiba ($machineName): $_"
            Write-Log $hiba "ERROR"
        }
    }
    else {
        Write-Log "Hianyzik CURTIME.txt: $($latestZip.Name)" "WARNING"
    }

    # Frissesség ellenőrzés
    if ($kulonbseg.Days -gt 2) {
        Write-Log "Regi mentes ($($kulonbseg.Days) napos): $machineName - $($latestZip.Name)" "WARNING"
    }

    # TEMP mappa törlése
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}


# CURTIME-ok egy mappába másolása
try {
    Get-ChildItem -Path (Join-Path $basePath "terulet") -Recurse -Filter *.txt |
    Where-Object {
        $_.DirectoryName -like "*\terulet*" -and
        $_.DirectoryName -notlike "*\terulet_ALL*"
    } |
    Copy-Item -Destination (Join-Path $basePath "terulet\terulet_ALL") -ErrorAction Stop
    Write-Log "CURTIME masolás kesz" "INFO"
}
catch {
    Write-Log "CURTIME masolasi hiba: $_" "ERROR"
}

Write-Log "Script befejezve" "INFO"
