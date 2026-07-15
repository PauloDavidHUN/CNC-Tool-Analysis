$baseUser  = $env:USERPROFILE
$basePath  = Join-Path $baseUser "ut1\ut2"
$baseNC    = Join-Path $baseUser "MES\ut1\ut2\Backups"
$logFile   = Join-Path $basePath "EGYEB\BACKUP_ERRORS.txt"

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

# Géplista beolvasása JSON-ból
$configPath = Join-Path $PSScriptRoot "machines.json"
try {
    $config = Get-Content $configPath -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json
}
catch {
    Write-Log "Konfig fajl nem olvasható: $configPath - $_" "ERROR"
    exit
}

# Tömb összerakása - SH szekció
$machines = @()
foreach ($line in $config.SH.PSObject.Properties) {
    foreach ($op in $line.Value) {
        $machines += Join-Path $baseNC "$($line.Name)\$op"
    }
}


foreach ($root in $machines) {

    # Gép és sor neve - előre, hogy a catch blokkokban is elérhető legyen
    $machineName = Split-Path $root -Leaf
    $lineName    = Split-Path (Split-Path $root -Parent) -Leaf

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
        Write-Log "Mappa nem elheto el ($root): $_" "ERROR"
        continue
    }

    if (-not $latestZip) {
        Write-Log "Nincs ZIP itt: $root" "WARNING"
        continue
    }

    $zipDate   = [datetime]::ParseExact($latestZip.Name.Substring(0,8), 'yyyyMMdd', $null)
    $kulonbseg = (Get-Date) - $zipDate

    # 2. Kibontás
    $tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString())
    try {
        Expand-Archive $latestZip.FullName $tmp -Force -ErrorAction Stop
    }
    catch {
        Write-Log "ZIP kibontasi hiba ($machineName - $($latestZip.Name)): $_" "ERROR"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
        continue
    }

    $sourceFile  = Get-ChildItem $tmp -Recurse -Filter DATA1.txt        -ErrorAction SilentlyContinue | Select-Object -First 1
    $sourceFile2 = Get-ChildItem $tmp -Recurse -Filter DATA2DAT.txt         -ErrorAction SilentlyContinue | Select-Object -First 1
    $sourceFile3 = Get-ChildItem $tmp -Recurse -Filter DATA1_SINGLE.txt -ErrorAction SilentlyContinue | Select-Object -First 1

    # Kimeneti mappák
    $outDirCUR = Join-Path $basePath "$lineName\MAIN"
    $outDirCT  = Join-Path $basePath "$lineName\DATA2"
    $outDirSIN = Join-Path $basePath "$lineName\DATA1"

    New-Item -ItemType Directory -Path $outDirCUR -Force | Out-Null
    New-Item -ItemType Directory -Path $outDirCT  -Force | Out-Null
    New-Item -ItemType Directory -Path $outDirSIN -Force | Out-Null

    # 3. Másolások
    if ($sourceFile) {
        try {
            Copy-Item $sourceFile.FullName (Join-Path $outDirCUR "${machineName}_MAIN.txt") -Force -ErrorAction Stop
        }
        catch {
            Write-Log "Masolasi hiba DATA1 ($machineName): $_" "ERROR"
        }
    }
    else {
        Write-Log "Hianyzik DATA1.txt: $($latestZip.Name)" "WARNING"
    }

    if ($sourceFile2) {
        try {
            Copy-Item $sourceFile2.FullName (Join-Path $outDirCT "${machineName}_DATA2.txt") -Force -ErrorAction Stop
        }
        catch {
            Write-Log "Masolasi hiba DATA2DAT ($machineName): $_" "ERROR"
        }
    }
    else {
        Write-Log "Hianyzik DATA2DAT.txt: $($latestZip.Name)" "WARNING"
    }

    if ($sourceFile3) {
        try {
            Copy-Item $sourceFile3.FullName (Join-Path $outDirSIN "${machineName}_DATA1.txt") -Force -ErrorAction Stop
        }
        catch {
            Write-Log "Masolasi hiba DATA1_SINGLE ($machineName): $_" "ERROR"
        }
    }
    else {
        Write-Log "Hianyzik DATA1_SINGLE.txt: $($latestZip.Name)" "WARNING"
    }

    # Frissesség ellenőrzés
    if ($kulonbseg.Days -gt 2) {
        Write-Log "Regi mentes ($($kulonbseg.Days) napos): $machineName - $($latestZip.Name)" "WARNING"
    }

    # TEMP mappa törlése
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# DATA1-ok egy mappába másolása
try {
    $destDir = Join-Path $basePath "DATA1_ALL"
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    Get-ChildItem -Path $basePath -Recurse -Filter *.txt |
    Where-Object {
        $_.DirectoryName -like "*\DATA1*" -and
        $_.DirectoryName -notlike "*\DATA1_ALL*"
    } |
    Copy-Item -Destination (Join-Path $basePath "DATA1_ALL") -ErrorAction Stop
    Write-Log "DATA1_ALL masolás kesz" "INFO"
}
catch {
    Write-Log "DATA1_ALL masolasi hiba: $_" "ERROR"
}

# DATA2-k egy mappába másolása
try {
    $destDir = Join-Path $basePath "DATA2_ALL"
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    Get-ChildItem -Path $basePath -Recurse -Filter *.txt |
    Where-Object {
        $_.DirectoryName -like "*\DATA2*" -and
        $_.DirectoryName -notlike "*\DATA2_ALL*"
    } |
    Copy-Item -Destination (Join-Path $basePath "DATA2ALL") -ErrorAction Stop
    Write-Log "DATA2ALL masolás kesz" "INFO"
}
catch {
    Write-Log "DATA2ALL masolasi hiba: $_" "ERROR"
}

# DATA3-k egy mappába másolása
try {
    $destDir = Join-Path $basePath "DATA3_ALL"
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    Get-ChildItem -Path $basePath -Recurse -Filter *.txt |
    Where-Object {
        $_.DirectoryName -like "*\DATA3*" -and
        $_.DirectoryName -notlike "*\DATA3_ALL*"
    } |
    Copy-Item -Destination (Join-Path $basePath "DATA3_ALL") -ErrorAction Stop
    Write-Log "DATA3_ALL masolás kesz" "INFO"
}
catch {
    Write-Log "MAIN_ALL masolasi hiba: $_" "ERROR"
}

Write-Log "Script befejezve" "INFO"
