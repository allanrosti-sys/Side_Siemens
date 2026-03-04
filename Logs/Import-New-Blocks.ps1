# Script: Importar Novos Blocos SCL
# Objetivo: Ler arquivos .scl de Logs\NewBlocks e injetar no TIA Portal

param(
    [switch]$Headless
)

$ErrorActionPreference = "Stop"

$projectRoot = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20"
$logsDir = Join-Path $projectRoot "Logs"
$exePath = Join-Path $logsDir "TiaBlockImporter_v20.exe"
$sclDir = Join-Path $logsDir "NewBlocks"
$projPath = Join-Path $projectRoot "tirol-ipiranga-os18869_20260224_PE_V20.ap20"
$buildScript = Join-Path $logsDir "Build_Importer.ps1"

Write-Host "=== IMPORTACAO DE BLOCOS SCL ===" -ForegroundColor Cyan
Write-Host ("MODO: " + ($(if ($Headless) { "Headless" } else { "Attach" }))) -ForegroundColor Yellow

if (-not (Test-Path $sclDir)) {
    New-Item -ItemType Directory -Path $sclDir | Out-Null
    Write-Host "Pasta NewBlocks criada: $sclDir" -ForegroundColor Yellow
}

# Se NewBlocks estiver vazio, usa os SCL de referencia em Logs\*.scl.
if ((Get-ChildItem -Path $sclDir -Filter *.scl -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
    $fallbackScls = Get-ChildItem -Path $logsDir -Filter *.scl -File -ErrorAction SilentlyContinue
    foreach ($f in $fallbackScls) {
        Copy-Item -Path $f.FullName -Destination (Join-Path $sclDir $f.Name) -Force
    }

    if ($fallbackScls.Count -gt 0) {
        Write-Host "NewBlocks estava vazio. Copiados $($fallbackScls.Count) arquivo(s) .scl de Logs para NewBlocks." -ForegroundColor Yellow
    }
}

if ((Get-ChildItem -Path $sclDir -Filter *.scl -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
    Write-Host "Nenhum arquivo .scl encontrado em $sclDir." -ForegroundColor Red
    Write-Host "Adicione arquivos .scl e execute novamente." -ForegroundColor Red
    exit 1
}

& $buildScript
if ($LASTEXITCODE -ne 0) {
    Write-Host "Falha ao compilar importador." -ForegroundColor Red
    exit 1
}

Write-Host "`nImportando de: $sclDir"
$arguments = @($sclDir, $projPath)
if ($Headless) {
    $arguments += "--headless"
}

if (-not (Test-Path $exePath)) {
    Write-Host "Executavel nao encontrado: $exePath" -ForegroundColor Red
    exit 1
}

& $exePath $arguments
if ($LASTEXITCODE -ne 0) {
    Write-Host "Importador retornou codigo de erro: $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`nVerifique no TIA Portal: External Sources e Program Blocks." -ForegroundColor Green
