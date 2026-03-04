# Monitor simples para AI_SYNC.md
$file = "c:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\AI_SYNC.md"
$lastTime = 0

Write-Host "Monitor iniciado. Verificando a cada 5 segundos..." -ForegroundColor Cyan

while (1) {
    $item = Get-Item $file -ErrorAction SilentlyContinue
    if ($item) {
        if ($item.LastWriteTime.Ticks -gt $lastTime) {
            $lastTime = $item.LastWriteTime.Ticks
            Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] ARQUIVO ATUALIZADO!" -ForegroundColor Yellow
            Write-Host "Lendo últimas linhas..." -ForegroundColor Cyan
            
            $content = Get-Content $file | Select-Object -Last 30
            $content | ForEach-Object { Write-Host $_ }
            
            Write-Host "`n✓ Nova mensagem detectada - verifique o arquivo" -ForegroundColor Green
        }
    }
    Start-Sleep -Seconds 5
}
