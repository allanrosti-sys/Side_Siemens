# Script: Build Importer
# Objetivo: Compilar a ferramenta de importacao de SCL

$ErrorActionPreference = "Stop"

$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$dllPath = "C:\Program Files\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll"
$sourcePath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\using Siemens_Import.cs"
$exePath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\TiaBlockImporter_v20.exe"

Write-Host "Compilando importador..." -ForegroundColor Cyan
Write-Host "Fonte: $sourcePath"
Write-Host "Saida: $exePath"

if (-not (Test-Path $cscPath)) {
    Write-Host "Compilador nao encontrado: $cscPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $dllPath)) {
    Write-Host "DLL Siemens.Engineering nao encontrada: $dllPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $sourcePath)) {
    Write-Host "Fonte nao encontrada: $sourcePath" -ForegroundColor Red
    exit 1
}

& $cscPath /nologo /target:exe /out:$exePath /reference:$dllPath $sourcePath
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro na compilacao do importador." -ForegroundColor Red
    exit 1
}

Write-Host "Compilacao concluida com sucesso." -ForegroundColor Green
