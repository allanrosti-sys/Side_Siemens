# Script: WebServer.ps1
# Objetivo: Servidor Web para controlar automacao TIA e visualizar estrutura do projeto.
# Autor: Equipe de IAs (Gemini/Copilot/Codex)
# Data: 2026-03-02

param(
    [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'

# --- CONFIGURACAO DO SERVIDOR HTTP ---
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()

Write-Host ("Servidor Web iniciado em http://localhost:{0}/" -f $Port) -ForegroundColor Cyan
Write-Host "Pressione Ctrl+C para parar."

# Define caminhos base para busca de scripts e arquivos
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot
$exportRoot = Join-Path $scriptRoot "ControlModules_Export"

# --- FUNCAO: GERAR DIAGRAMA MERMAID ---
# Gera a definicao de grafico para o Mermaid.js baseada na estrutura de pastas exportada
function New-ProjectMermaid {
    param([string]$ExportPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("graph TD")
    $lines.Add("  ROOT[`"Projeto TIA Portal`"]")

    # Verifica se a pasta de exportacao existe
    if (-not (Test-Path $ExportPath)) {
        $lines.Add("  ROOT --> NODATA[`"Sem exportacao: execute Exportar Projeto`"]")
        return ($lines -join "`n")
    }

    # Busca todos os arquivos XML recursivamente
    $allXml = Get-ChildItem -Path $ExportPath -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue
    if ($allXml.Count -eq 0) {
        $lines.Add("  ROOT --> EMPTY[`"Sem XML no ControlModules_Export`"]")
        return ($lines -join "`n")
    }

    $obCount = ($allXml | Where-Object { $_.Name -like 'OB_*' }).Count
    $fbCount = ($allXml | Where-Object { $_.Name -like 'FB_*' }).Count
    $fcCount = ($allXml | Where-Object { $_.Name -like 'FC_*' }).Count

    # Adiciona estatisticas ao grafico
    $lines.Add("  ROOT --> STATS[`"Blocos exportados: $($allXml.Count)`"]")
    $lines.Add("  STATS --> OB[`"OB: $obCount`"]")
    $lines.Add("  STATS --> FB[`"FB: $fbCount`"]")
    $lines.Add("  STATS --> FC[`"FC: $fcCount`"]")

    # Adiciona nos para cada pasta de primeiro nivel
    $topDirs = Get-ChildItem -Path $ExportPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name
    $index = 0
    foreach ($dir in $topDirs) {
        $index++
        $node = "G$index"
        $safeName = $dir.Name.Replace('"', "'")
        $xmlCount = (Get-ChildItem -Path $dir.FullName -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        $lines.Add("  ROOT --> $node[`"$safeName ($xmlCount)`"]")
    }

    return ($lines -join "`n")
}

# --- LOOP PRINCIPAL DO SERVIDOR ---
while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $path = $request.Url.LocalPath
    $method = $request.HttpMethod

    Write-Host "[$method] $path" -ForegroundColor Gray

    $content = ""
    $contentType = "text/html; charset=utf-8"
    $statusCode = 200

    try {
        # ROTA: Pagina Principal (index.html)
        if ($path -eq "/" -or $path -eq "/index.html") {
            $htmlPath = Join-Path $scriptRoot "index.html"
            if (Test-Path $htmlPath) {
                $content = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
            } else {
                $content = "<h1>Erro: index.html nao encontrado</h1>"
                $statusCode = 404
            }
        }
        # ROTA: Executar Script (/api/run) - Metodo POST
        elseif ($path -eq "/api/run" -and $method -eq "POST") {
            $reader = [System.IO.StreamReader]::new($request.InputStream, [System.Text.Encoding]::UTF8)
            $body = $reader.ReadToEnd()
            $reader.Dispose()

            $json = $body | ConvertFrom-Json
            $scriptName = [string]$json.script

            # Lista de scripts permitidos por seguranca
            $allowedScripts = @(
                "RunExporterWithAttach.ps1",
                "Import-New-Blocks.ps1",
                "Run-Full-Cycle.ps1",
                "Generate-Documentation.ps1"
            )

            # Verifica se o script esta na lista permitida e se existe no disco
            if ($allowedScripts -contains $scriptName) {
                $possiblePaths = @(
                    (Join-Path $scriptRoot $scriptName),
                    (Join-Path $projectRoot $scriptName)
                )
                $targetScript = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
            } else {
                $targetScript = $null
            }

            if ($targetScript) {
                Write-Host "Executando: $scriptName" -ForegroundColor Yellow

                # Inicia o script em um Job separado para nao travar o servidor web
                Start-Job -ScriptBlock {
                    param($s)
                    powershell -ExecutionPolicy Bypass -File $s
                } -ArgumentList $targetScript | Out-Null

                $content = (@{ status = "success"; message = "Script iniciado em background." } | ConvertTo-Json -Compress)
                $contentType = "application/json; charset=utf-8"
            } else {
                $content = (@{ status = "error"; message = "Script nao permitido ou nao encontrado." } | ConvertTo-Json -Compress)
                $statusCode = 404
                $contentType = "application/json; charset=utf-8"
            }
        }
        # ROTA: Obter Logs (/api/logs)
        elseif ($path -eq "/api/logs") {
            $logFile = Get-ChildItem -Path $scriptRoot -Filter "run_output_*.txt" -File -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1

            if ($null -ne $logFile) {
                $logContent = Get-Content -Path $logFile.FullName -Raw -Encoding UTF8
                $content = (@{ log = $logContent } | ConvertTo-Json -Compress)
            } else {
                $content = (@{ log = "Nenhum log encontrado." } | ConvertTo-Json -Compress)
            }

            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Obter Diagrama Mermaid (/api/mermaid)
        elseif ($path -eq "/api/mermaid") {
            $diagram = New-ProjectMermaid -ExportPath $exportRoot
            $content = (@{ diagram = $diagram } | ConvertTo-Json -Compress)
            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Nao Encontrado (404)
        else {
            $content = "404 - Nao encontrado"
            $statusCode = 404
        }
    }
    catch {
        # Tratamento global de erros (500)
        $errMsg = "500 - Erro interno: $($_.Exception.Message)"
        $statusCode = 500
        Write-Error $_

        if ($path -like "/api/*") {
            $content = (@{ status = "error"; message = $errMsg } | ConvertTo-Json -Compress)
            $contentType = "application/json; charset=utf-8"
        } else {
            $content = $errMsg
            $contentType = "text/html; charset=utf-8"
        }
    }

    # Envia a resposta para o navegador
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
    $response.ContentLength64 = $buffer.Length
    $response.ContentType = $contentType
    $response.StatusCode = $statusCode
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
}
