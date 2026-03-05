# Script: Fix-TiaMap.ps1
# Objetivo: Forcar o encerramento de todos os processos do backend do TIA Map (uvicorn).

Write-Host "Procurando por processos do backend TIA Map (uvicorn)..." -ForegroundColor Yellow

$processes = Get-CimInstance Win32_Process | Where-Object {
    ($_.Name -match 'python|py.exe') -and ($_.CommandLine -match "uvicorn main:app")
}

if ($null -eq $processes) {
    Write-Host "Nenhum processo do backend TIA Map encontrado." -ForegroundColor Green
    exit 0
}

$processCount = ($processes | Measure-Object).Count
Write-Host "Encontrado(s) $processCount processo(s). Encerrando..." -ForegroundColor Yellow

foreach ($proc in $processes) {
    $processId = $proc.ProcessId
    $cmd = $proc.CommandLine
    Write-Host "  - Encerrando PID: ${processId}"
    Write-Host "    Comando: $cmd" -ForegroundColor DarkGray
    try {
        Stop-Process -Id $processId -Force -ErrorAction Stop
        Write-Host "    Processo ${processId} encerrado com sucesso." -ForegroundColor Green
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Warning "    Falha ao encerrar processo ${processId}: $errorMessage"
    }
}

Write-Host "Limpeza concluida."
