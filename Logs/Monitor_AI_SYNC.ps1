# Monitor AI_SYNC.md para mensagens endereçadas a Copilot
# Script de monitoramento contínuo com alertas

$syncFile = "c:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\AI_SYNC.md"
$lastHash = $null
$lastLineCount = 0

Write-Host "=== Monitor AI_SYNC.md Iniciado ===" -ForegroundColor Cyan
Write-Host "Monitorando: $syncFile" -ForegroundColor Yellow
Write-Host "Procurando mensagens endereçadas a: Copilot, Você, copilot" -ForegroundColor Yellow
Write-Host "Pressione Ctrl+C para parar." -ForegroundColor Cyan
Write-Host ""

while ($true) {
    try {
        if (Test-Path $syncFile) {
            $content = Get-Content $syncFile -Raw
            $currentHash = [System.Security.Cryptography.SHA256]::ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content)) | ConvertTo-Hex
            $lineCount = (Get-Content $syncFile | Measure-Object -Line).Lines
            
            if ($lastHash -ne $currentHash) {
                Write-Host "`n[$(Get-Date -Format 'HH:mm:ss')] ⚠️  ARQUIVO ATUALIZADO!" -ForegroundColor Green
                Write-Host "Linhas: $lastLineCount → $lineCount" -ForegroundColor Cyan
                
                # Procurar por mensagens endereçadas a Copilot
                $lines = Get-Content $syncFile
                $foundCopilot = $false
                
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    $line = $lines[$i]
                    if ($line -match "(Copilot|copilot|Você)" -and $line -match "^##|->|Request|request|Action") {
                        if (-not $foundCopilot) {
                            Write-Host "`n📬 NOVA MENSAGEM PARA COPILOT:" -ForegroundColor Yellow
                            Write-Host "─" * 60 -ForegroundColor Yellow
                            $foundCopilot = $true
                        }
                        Write-Host $line -ForegroundColor White
                    }
                }
                
                if ($foundCopilot) {
                    Write-Host "─" * 60 -ForegroundColor Yellow
                    Write-Host "✓ Verifique AI_SYNC.md para detalhes completos" -ForegroundColor Green
                }
                
                $lastHash = $currentHash
                $lastLineCount = $lineCount
            }
            else {
                Write-Host "." -NoNewline -ForegroundColor Gray
            }
        }
    }
    catch {
        Write-Host "`n❌ Erro: $_" -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 3
}
