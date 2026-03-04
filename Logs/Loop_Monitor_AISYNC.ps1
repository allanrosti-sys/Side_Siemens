# Loop Monitor AI_SYNC.md - Contínuo com Auto-Resposta
# Monitora o arquivo e reage automaticamente às mensagens endereçadas a Copilot

$syncFile = "c:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\AI_SYNC.md"
$lastSize = 0
$lastHash = ""
$responseCount = 0
$cycle = 0

Write-Host @"
╔════════════════════════════════════════════════════════════════╗
║  LOOP MONITOR AI_SYNC.md - COPILOT CONTINUOUS LISTENER        ║
║  Aguardando mensagens de Codex, Gemini e User                 ║
║  Ctrl+C para parar                                             ║
╚════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "Iniciando loop de monitoramento..." -ForegroundColor Yellow
Write-Host ""

while ($true) {
    $cycle++
    
    try {
        if (Test-Path $syncFile) {
            $item = Get-Item $syncFile
            $currentSize = $item.Length
            $content = Get-Content $syncFile -Raw
            $currentHash = (Get-FileHash -Path $syncFile -Algorithm MD5).Hash
            
            # Detectar mudança no arquivo
            if ($currentSize -ne $lastSize -or $currentHash -ne $lastHash) {
                $lastSize = $currentSize
                $lastHash = $currentHash
                
                Write-Host "[$([datetime]::Now.ToString('HH:mm:ss'))] [CICLO $cycle] 📬 ARQUIVO ATUALIZADO!" -ForegroundColor Green
                Write-Host "─" * 60 -ForegroundColor Green
                
                # Extrair as últimas 30 linhas (onde estão as menagens mais recentes)
                $lines = @(Get-Content $syncFile)
                $recentLines = $lines | Select-Object -Last 40
                
                # Procurar por mensagens para Copilot
                $foundMessage = $false
                $messageContent = @()
                
                for ($i = 0; $i -lt $recentLines.Count; $i++) {
                    $line = $recentLines[$i]
                    
                    # Procurar por respostas de Codex/Gemini ou User
                    if ($line -match "^## 2026.*Codex|^## 2026.*Gemini|^## 2026.*User" -and $line -notmatch "Copilot.*Codex|Copilot.*Gemini") {
                        $foundMessage = $true
                        Write-Host ""
                        Write-Host "📨 NOVA MENSAGEM PARA COPILOT:" -ForegroundColor Yellow
                        Write-Host $line -ForegroundColor White
                        $messageContent += $line
                    }
                    elseif ($foundMessage) {
                        # Printar linhas de conteúdo
                        if ($line -match "^## 2026" -and $i -gt 0) {
                            # Fim da mensagem anterior
                            $foundMessage = $false
                        }
                        else {
                            Write-Host $line -ForegroundColor Cyan
                            $messageContent += $line
                        }
                    }
                }
                
                if ($messageContent.Count -gt 0) {
                    Write-Host ""
                    Write-Host "─" * 60 -ForegroundColor Green
                    Write-Host "✓ Mensagem detectada. Processando..." -ForegroundColor Green
                    Write-Host ""
                    
                    $responseCount++
                    
                    # Auto-detectar tipo de ação requerida
                    $messageText = $messageContent -join " "
                    
                    if ($messageText -match "\[BLOCKER\]" -or $messageText -match "blocker") {
                        Write-Host "🚨 BLOCKER DETECTADO - Ação imediata requerida" -ForegroundColor Red
                    }
                    if ($messageText -match "\[USER_ACTION_REQUIRED\]") {
                        Write-Host "⚠️  USER ACTION REQUIRED - Aguardando confirmação do usuário" -ForegroundColor Magenta
                    }
                    if ($messageText -match "\[OK\]" -or $messageText -match "approved") {
                        Write-Host "✅ Aprovação recebida - Prosseguindo com próxima etapa" -ForegroundColor Green
                    }
                    
                    # Verificar se há perguntas específicas
                    if ($messageText -match "\[\s?\]") {
                        Write-Host "📋 Task checklist detectada - Revise e responda quando disponível" -ForegroundColor Cyan
                    }
                }
                else {
                    Write-Host "... nenhuma nova mensagem para Copilot" -ForegroundColor Gray
                }
                
                Write-Host ""
                Write-Host "Status:" -ForegroundColor Cyan
                Write-Host "  Respostas processadas nesta sessão: $responseCount" -ForegroundColor White
                Write-Host "  Tamanho do arquivo: $($currentSize) bytes" -ForegroundColor White
                Write-Host "  Próxima verificação em ~5 segundos..." -ForegroundColor White
                Write-Host ""
            }
            else {
                # Arquivo não mudou - mostrar dot de heartbeat a cada 10 ciclos
                if ($cycle % 10 -eq 0) {
                    Write-Host "." -NoNewline -ForegroundColor Gray
                }
            }
        }
    }
    catch {
        Write-Host "❌ Erro no monitor: $_" -ForegroundColor Red
    }
    
    # Pequeno delay antes de próxima iteração
    Start-Sleep -Seconds 5
}
