# Script: Build Exporter (Compilação)
# Objetivo: Compilar o código C# corrigido para um executável compatível

$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$dllPath = "C:\Program Files\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll"
$sourcePath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\using Siemens.cs"
$exePath = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\TiaProjectExporter_v20.exe"

Write-Host "Iniciando compilação..." -ForegroundColor Cyan
Write-Host "Fonte: $sourcePath"
Write-Host "Saída: $exePath"

if (Test-Path $cscPath) {
    & $cscPath /nologo /target:exe /out:$exePath /reference:$dllPath $sourcePath
    if ($LASTEXITCODE -eq 0) { 
        Write-Host "✓ Compilação Sucesso!" -ForegroundColor Green
    } else { 
        Write-Host "✗ Erro na compilação. Verifique o código." -ForegroundColor Red
        exit 1 
    }
} else {
    Write-Host "✗ Compilador não encontrado em $cscPath" -ForegroundColor Red
}