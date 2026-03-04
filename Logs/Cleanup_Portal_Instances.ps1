# Script para limpar instâncias duplicadas de TIA Portal
# Retém apenas a instância mais recente
# AVISO: Será um force-close, então salve tudo no Portal antes de executar

Write-Host "=== CLEANUP PORTAL INSTANCES ===" -ForegroundColor Cyan
Write-Host ""

# Encontrar instâncias do Portal
$portals = Get-Process | Where-Object { $_.Name -eq "Siemens.Automation.Portal" }

if ($portals.Count -lt 2) {
    Write-Host "✓ Apenas uma ou nenhuma instância de Portal encontrada. Nada a fazer." -ForegroundColor Green
    exit 0
}

Write-Host "Encontradas $($portals.Count) instâncias de Portal:" -ForegroundColor Yellow
$portals | ForEach-Object {
    Write-Host "  - PID: $($_.Id), Iniciada: $($_.StartTime)" -ForegroundColor White
}

Write-Host ""
Write-Host "Será fechada a instância MAIS ANTIGA (menor ID ou StartTime mais recuada)..." -ForegroundColor Yellow

# Ordenar por StartTime e pegar a mais antiga
$oldest = $portals | Sort-Object StartTime | Select-Object -First 1
$newest = $portals | Sort-Object StartTime | Select-Object -Last 1

Write-Host ""
Write-Host "Instância a FECHAR: PID=$($oldest.Id) (iniciada $($oldest.StartTime))" -ForegroundColor Red
Write-Host "Instância a MANTER:  PID=$($newest.Id) (iniciada $($newest.StartTime))" -ForegroundColor Green
Write-Host ""

$response = Read-Host "Tem certeza? Digite 'sim' para confirmar"

if ($response -eq "sim") {
    Write-Host ""
    Write-Host "Fechando PID=$($oldest.Id)..." -ForegroundColor Yellow
    
    try {
        Stop-Process -Id $oldest.Id -Force -ErrorAction Stop
        Write-Host "✓ Sucesso! Instância $($oldest.Id) fechada." -ForegroundColor Green
        
        Start-Sleep -Seconds 3
        
        $remaining = Get-Process | Where-Object { $_.Name -eq "Siemens.Automation.Portal" }
        Write-Host ""
        Write-Host "Instâncias restantes: $($remaining.Count)" -ForegroundColor Cyan
        if ($remaining) {
            $remaining | ForEach-Object {
                Write-Host "  - PID: $($_.Id)" -ForegroundColor White
            }
        }
    }
    catch {
        Write-Host "✗ Erro ao fechar processo: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Cancelado." -ForegroundColor Yellow
}
