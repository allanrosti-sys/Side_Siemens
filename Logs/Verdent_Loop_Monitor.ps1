param(
    [int]$IntervalSeconds = 30,
    [int]$MaxCiclos = 40
)

$file = 'c:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\AI_SYNC.md'
$lastSize = (Get-Item $file).Length
$ciclo = 1

Write-Host "=== VERDENT LOOP MONITOR ===" -ForegroundColor Cyan
Write-Host "Monitorando: $file" -ForegroundColor Gray
Write-Host "Intervalo: $IntervalSeconds segundos | Max ciclos: $MaxCiclos" -ForegroundColor Gray
Write-Host "Aguardando respostas de Codex, Gemini e Copilot..." -ForegroundColor Yellow
Write-Host "---"

$respostasRecebidas = @()

while ($ciclo -le $MaxCiclos) {
    Start-Sleep -Seconds $IntervalSeconds
    $currentSize = (Get-Item $file).Length

    if ($currentSize -ne $lastSize) {
        $diff = $currentSize - $lastSize
        Write-Host "[$ciclo] ALTERACAO DETECTADA! +$diff bytes" -ForegroundColor Green

        $linhas = Get-Content $file -Encoding UTF8
        $novasLinhas = $linhas | Select-Object -Last 60
        Write-Host "--- NOVO CONTEUDO (ultimas linhas) ---" -ForegroundColor Cyan
        $novasLinhas | ForEach-Object { Write-Host $_ }
        Write-Host "--- FIM ---" -ForegroundColor Cyan

        foreach ($ia in @("Codex", "Gemini", "Copilot")) {
            $pattern = "RESPOSTA CONSULTA TIA Map"
            if (($novasLinhas -join "`n") -match $ia -and ($novasLinhas -join "`n") -match $pattern) {
                if ($respostasRecebidas -notcontains $ia) {
                    $respostasRecebidas += $ia
                    Write-Host "[$ia] RESPONDEU A CONSULTA!" -ForegroundColor Magenta
                }
            }
        }

        Write-Host "Respostas recebidas ate agora: $($respostasRecebidas -join ', ')" -ForegroundColor Yellow

        if ($respostasRecebidas.Count -ge 3) {
            Write-Host "TODAS AS IAs RESPONDERAM! Loop encerrado." -ForegroundColor Green
            break
        }

        $lastSize = $currentSize
    } else {
        Write-Host "[$ciclo] Sem alteracoes. ($lastSize bytes)" -ForegroundColor Gray
    }

    $ciclo++
}

if ($respostasRecebidas.Count -lt 3) {
    $faltando = @("Codex","Gemini","Copilot") | Where-Object { $respostasRecebidas -notcontains $_ }
    Write-Host "Loop encerrado. Ainda aguardando: $($faltando -join ', ')" -ForegroundColor Yellow
}
