$machines = @(

											
#LEANLINE1
    "C:\Users\YOUR_USERNAME\LEANLINE1\LEANLINE1_OP10",
    "C:\Users\YOUR_USERNAME\LEANLINE1\LEANLINE1_OP20", 
    "C:\Users\YOUR_USERNAME\LEANLINE1\LEANLINE1_OP30", 
    "C:\Users\YOUR_USERNAME\LEANLINE1\LEANLINE1_OP40", 
    "C:\Users\YOUR_USERNAME\LEANLINE1\LEANLINE1_OP50", 
    "C:\Users\YOUR_USERNAME\LEANLINE1\LEANLINE1_OP60", 
 

#LEANLINE2
    "C:\Users\YOUR_USERNAME\LEANLINE2\LEANLINE2_OP05",   
    "C:\Users\YOUR_USERNAME\LEANLINE2\LEANLINE2_OP10", 
    "C:\Users\YOUR_USERNAME\LEANLINE2\LEANLINE2_OP20",   
    "C:\Users\YOUR_USERNAME\LEANLINE2\LEANLINE2_OP30",    
    "C:\Users\YOUR_USERNAME\LEANLINE2\LEANLINE2_OP40",    
    "C:\Users\YOUR_USERNAME\LEANLINE2\LEANLINE2_OP50",    
    "C:\Users\YOUR_USERNAME\LEANLINE2\LEANLINE2_OP60", 

											
#LEANLINE3
    "C:\Users\YOUR_USERNAME\LEANLINE3\LEANLINE3_OP10", 
    "C:\Users\YOUR_USERNAME\LEANLINE3\LEANLINE3_OP20", 
    "C:\Users\YOUR_USERNAME\LEANLINE3\LEANLINE3_OP30", 
    "C:\Users\YOUR_USERNAME\LEANLINE3\LEANLINE3_OP40", 
    "C:\Users\YOUR_USERNAME\LEANLINE3\LEANLINE3_OP50", 
    "C:\Users\YOUR_USERNAME\LEANLINE3\LEANLINE3_OP60", 
    "C:\Users\YOUR_USERNAME\LEANLINE3\LEANLINE3_OP70",


#LEANLINE4
    "C:\Users\YOUR_USERNAME\LEANLINE4\LEANLINE4_OP10", 
    "C:\Users\YOUR_USERNAME\LEANLINE4\LEANLINE4_OP20", 
    "C:\Users\YOUR_USERNAME\LEANLINE4\LEANLINE4_OP30", 
    "C:\Users\YOUR_USERNAME\LEANLINE4\LEANLINE4_OP40", 


#LEANLINE5
    "C:\Users\YOUR_USERNAME\LEANLINE5\LEANLINE5_OP10",  
    "C:\Users\YOUR_USERNAME\LEANLINE5\LEANLINE5_OP20",  
    "C:\Users\YOUR_USERNAME\LEANLINE5\LEANLINE5_OP30",  
    "C:\Users\YOUR_USERNAME\LEANLINE5\LEANLINE5_OP40",  
    "C:\Users\YOUR_USERNAME\LEANLINE5\LEANLINE5_OP50",  
    "C:\Users\YOUR_USERNAME\LEANLINE5\LEANLINE5_OP60",  

	
#LEANLINE6 
    "C:\Users\YOUR_USERNAME\LEANLINE6\LEANLINE6_OP10", 
    "C:\Users\YOUR_USERNAME\LEANLINE6\LEANLINE6_OP20", 
    "C:\Users\YOUR_USERNAME\LEANLINE6\LEANLINE6_OP30", 
    "C:\Users\YOUR_USERNAME\LEANLINE6\LEANLINE6_OP40", 
    "C:\Users\YOUR_USERNAME\LEANLINE6\LEANLINE6_OP50", 
    "C:\Users\YOUR_USERNAME\LEANLINE6\LEANLINE6_OP60", 
    
#LEANLINE7
    "C:\Users\YOUR_USERNAME\LEANLINE7\LEANLINE7_OP10", 
    "C:\Users\YOUR_USERNAME\LEANLINE7\LEANLINE7_OP20", 
    "C:\Users\YOUR_USERNAME\LEANLINE7\LEANLINE7_OP30", 
    "C:\Users\YOUR_USERNAME\LEANLINE7\LEANLINE7_OP40", 
    "C:\Users\YOUR_USERNAME\LEANLINE7\LEANLINE7_OP50", 
    "C:\Users\YOUR_USERNAME\LEANLINE7\LEANLINE7_OP60"

)

foreach ($root in $machines) {

    # 1. Legfrissebb ZIP 

    $latestZip =
        Get-ChildItem $root -Filter *.zip |
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

    if (-not $latestZip) {
        Write-Host "Nincs ZIP itt: $root"
        continue
    }

    # 2. Kibontás

   #$tmp = "$env:TEMP\ziptmp" # régi fix temp mappa ahova ideiglenesen ment

    $tmp = Join-Path $env:TEMP ([guid]::NewGuid().ToString())   # egyedi temp mappa, ütközés ellen automatizációhoz
    Expand-Archive $latestZip.FullName $tmp -Force


    $sourceFile  = Get-ChildItem $tmp -Recurse -Filter TOOLTIME_SINGLE.txt -ErrorAction SilentlyContinue | Select-Object -First 1
    $sourceFile2 = Get-ChildItem $tmp -Recurse -Filter CYCLETIME.txt  -ErrorAction SilentlyContinue | Select-Object -First 1


    # Gép neve (pl. LEANLINE7_OP10)
    $machineName = Split-Path $root -Leaf

    # Sor neve (pl. LEANLINE7)
    $lineName = Split-Path (Split-Path $root -Parent) -Leaf

    # Kimeneti mappák

    $outDirCUR = "C:\Users\YOUR_USERNAME\REG_DATA\$lineName\TOOLTIME"
    $outDirCT = "C:\Users\YOUR_USERNAME\REG_DATA\$lineName\CT"

    New-Item -ItemType Directory -Path $outDirCUR -Force | Out-Null 
    New-Item -ItemType Directory -Path $outDirCT -Force  | Out-Null

    if ($sourceFile) {
        $fileName = "${machineName}_TOOLTIME.txt"
        Copy-Item $sourceFile.FullName (Join-Path $outDirCUR $fileName) -Force
    }
    else {
        Write-Host "Hiányzik TOOLTIME.txt: $($latestZip.Name)"
    }


    if ($sourceFile2) {
        $fileName2 = "${machineName}_CT.txt"
        Copy-Item $sourceFile2.FullName (Join-Path $outDirCT $fileName2) -Force
    }
    else {
        Write-Host "Hiányzik CYCLETIME.txt: $($latestZip.Name)"
    }


	# TEMP mappa törlése
	Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue

}

# TOOLTIME-ok egy mappába másolása
Get-ChildItem -Path "C:\Users\YOUR_USERNAME\REG_DATA" -Recurse -Filter *.txt |
Where-Object {
	$_.DirectoryName -like "*\TOOLTIME*" -and
	$_.DirectoryName -notlike "*\TOOLTIME_ALL*"   # <-- kizárja az ALL mappát
} |
Copy-Item -Destination "C:\Users\YOUR_USERNAME\REG_DATA\TOOLTIME_ALL"


# CT-k egy mappába másolása
Get-ChildItem -Path "C:\Users\YOUR_USERNAME\REG_DATA" -Recurse -Filter *.txt |
Where-Object { 
	$_.DirectoryName -like "*\CT*" -and
	$_.DirectoryName -notlike "*\CT_ALL*"        # <-- kizárja az ALL mappát
} |
Copy-Item -Destination "C:\Users\YOUR_USERNAME\REG_DATA\CT_ALL"


