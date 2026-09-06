# ==============================================================================
# Local Best Practice Analyzer (BPA) Verification Script
# ==============================================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 🚀 LOCAL TABULAR EDITOR BEST PRACTICE ANALYZER CHECK" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$modelDir = Join-Path $projectRoot "src\Brightline_Sales.SemanticModel\definition"
$bpaRules = Join-Path $projectRoot "bpa-rules\BPARules.json"
$tempDir = Join-Path $projectRoot "TabularEditor"

$teExe = Join-Path $tempDir "TabularEditor.exe"

if (!(Test-Path $teExe)) {
    Write-Host "Downloading Tabular Editor Portable CLI v2.28.0..." -ForegroundColor Yellow
    $url = "https://github.com/TabularEditor/TabularEditor/releases/download/2.28.0/TabularEditor.Portable.zip"
    $zip = Join-Path $projectRoot "TabularEditor.zip"
    Invoke-WebRequest -Uri $url -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $tempDir -Force
    Remove-Item $zip -Force
}

$bpaReport = Join-Path $projectRoot "bpa-report.txt"
if (Test-Path $bpaReport) { Remove-Item $bpaReport -Force }

Write-Host "Scanning TMDL Model : $modelDir" -ForegroundColor Gray
Write-Host "Applying BPA Rules  : $bpaRules" -ForegroundColor Gray
Write-Host "Output Report Path  : $bpaReport" -ForegroundColor Gray
Write-Host ""

$proc = Start-Process -FilePath $teExe -ArgumentList "`"$modelDir`" -A `"$bpaRules`" -B `"$bpaReport`" -W -V" -NoNewWindow -PassThru -Wait

if (Test-Path $bpaReport) {
    Write-Host "`n--- BPA Report Summary ---" -ForegroundColor Yellow
    Get-Content $bpaReport | ForEach-Object { Write-Host $_ }
    Write-Host "--------------------------`n"
}

if ($proc.ExitCode -ne 0) {
    Write-Host "❌ BPA Validation Failed with exit code $($proc.ExitCode)! Violations detected." -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ SUCCESS: All Best Practice Analyzer rules passed 100%!" -ForegroundColor Green
    exit 0
}
