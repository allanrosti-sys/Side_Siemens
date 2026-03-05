# Script: Limpeza de Artefatos de Frontend
# Objetivo: Remover componentes React temporarios da pasta Logs, ja que agora residem em tia-map/frontend

$logsDir = "C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs"
$artifacts = @("CodeViewer.tsx", "FilterPanel.tsx", "DetailPanel.tsx")

Write-Host "=== LIMPEZA DE ARTEFATOS OBSOLETOS ===" -ForegroundColor Cyan

foreach ($file in $artifacts) {
    $path = Join-Path $logsDir $file
    if (Test-Path $path) {
        Remove-Item -Path $path -Force
        Write-Host "Removido: $file (Duplicata obsoleta)" -ForegroundColor Yellow
    } else {
        Write-Host "Nao encontrado: $file (Ja limpo)" -ForegroundColor Gray
    }
}

Write-Host "Limpeza concluida. Componentes oficiais estao em tia-map/frontend/src/components." -ForegroundColor Green