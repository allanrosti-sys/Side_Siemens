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
$settingsFile = Join-Path $scriptRoot "web_settings.json"
$selectedTiaPath = $null

if (Test-Path $settingsFile) {
    try {
        $settings = Get-Content -Path $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($settings.tiaPath) {
            $selectedTiaPath = [string]$settings.tiaPath
        }
    } catch {
        Write-Warning "Falha ao ler web_settings.json: $($_.Exception.Message)"
    }
}

function Save-WebSettings {
    param([string]$TiaPath)
    $obj = @{ tiaPath = $TiaPath }
    $json = $obj | ConvertTo-Json -Compress
    Set-Content -Path $settingsFile -Value $json -Encoding UTF8
}

function Resolve-ExportPath {
    param([string]$BasePath, [string]$FallbackPath)

    $candidates = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($BasePath)) {
        $candidates.Add((Join-Path $BasePath "Logs\\ControlModules_Export"))
        $candidates.Add((Join-Path $BasePath "ControlModules_Export"))
        $candidates.Add((Join-Path $BasePath "Logs"))
        $candidates.Add($BasePath)
    }
    $candidates.Add($FallbackPath)

    foreach ($candidate in $candidates) {
        if (-not (Test-Path $candidate)) { continue }
        $xmlCount = (Get-ChildItem -Path $candidate -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($xmlCount -gt 0) { return $candidate }
    }

    return $FallbackPath
}

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

# --- FUNCAO: GERAR DIAGRAMA DE EXECUCAO (CALL GRAPH) ---
# Le os XML exportados e monta um fluxo de chamadas entre OB/FC/FB/DB.
function New-ExecutionMermaid {
    param([string]$ExportPath)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("graph TD")
    $lines.Add("  ROOT[`"Sequencia de Execucao PLC`"]")

    if (-not (Test-Path $ExportPath)) {
        $lines.Add("  ROOT --> NODATA[`"Sem exportacao`"]")
        return ($lines -join "`n")
    }

    function Get-SafeId([string]$text) {
        if ([string]::IsNullOrWhiteSpace($text)) { return "N_EMPTY" }
        $safe = ($text -replace '[^A-Za-z0-9_]', '_')
        if ($safe -match '^[0-9]') { $safe = "N_$safe" }
        return "N_$safe"
    }

    $xmlFiles = Get-ChildItem -Path $ExportPath -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue
    if ($xmlFiles.Count -eq 0) {
        $lines.Add("  ROOT --> EMPTY[`"Sem XMLs para analisar`"]")
        return ($lines -join "`n")
    }
    if ($xmlFiles.Count -lt 20) {
        $lines.Add("  ROOT --> WARN[`"Atencao: export parcial ($($xmlFiles.Count) XML). Rode Exportar Projeto para visao completa.`"]")
    }

    $nodeMap = @{}
    $incomingCount = @{}
    $edgeSet = New-Object 'System.Collections.Generic.HashSet[string]'

    foreach ($file in $xmlFiles) {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        $callerType = $null
        $callerName = $null

        if ($file.BaseName -match '^(OB|FB|FC)_(.+)$') {
            $callerType = $matches[1].ToUpper()
            $callerName = $matches[2]
        } else {
            if ($content -match '<SW\.Blocks\.(OB|FB|FC)\b') {
                $callerType = $matches[1].ToUpper()
            }
            if ($content -match '<Name>([^<]+)</Name>') {
                $callerName = $matches[1]
            } elseif ($content -match '<ConstantName[^>]*>([^<]+)</ConstantName>') {
                $callerName = $matches[1]
            }
        }

        if (-not $callerType -or -not $callerName) { continue }

        $callerLabel = "$callerType $callerName"
        $callerId = Get-SafeId $callerLabel
        $nodeMap[$callerId] = $callerLabel

        # Liga raiz aos OBs para evidenciar ponto de entrada do ciclo.
        if ($callerType -eq "OB") {
            $edgeKey = "ROOT|$callerId"
            if ($edgeSet.Add($edgeKey)) {
                $lines.Add("  ROOT --> $callerId")
            }
        }

        $callMatches = [regex]::Matches($content, '<CallInfo\s+Name="([^"]+)"\s+BlockType="([^"]+)"[^>]*>(.*?)</CallInfo>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        foreach ($call in $callMatches) {
            $targetName = $call.Groups[1].Value
            $targetType = $call.Groups[2].Value.ToUpper()
            if ([string]::IsNullOrWhiteSpace($targetName)) { continue }

            $targetLabel = "$targetType $targetName"
            $targetId = Get-SafeId $targetLabel
            $nodeMap[$targetId] = $targetLabel

            $edgeKey = "$callerId|$targetId"
            if ($edgeSet.Add($edgeKey)) {
                $lines.Add("  $callerId --> $targetId")
                if (-not $incomingCount.ContainsKey($targetId)) { $incomingCount[$targetId] = 0 }
                $incomingCount[$targetId]++
            }

            # Mapeia instancia DB dentro da chamada (quando existir).
            $instanceNameMatch = [regex]::Match($call.Groups[3].Value, '<Component\s+Name="([^"]+)"')
            if ($instanceNameMatch.Success) {
                $instanceName = $instanceNameMatch.Groups[1].Value
                if ($instanceName -match '^(?i)db') {
                    $dbLabel = "DB $instanceName"
                    $dbId = Get-SafeId $dbLabel
                    $nodeMap[$dbId] = $dbLabel

                    $dbEdgeKey = "$callerId|$dbId"
                    if ($edgeSet.Add($dbEdgeKey)) {
                        $lines.Add("  $callerId --> $dbId")
                        if (-not $incomingCount.ContainsKey($dbId)) { $incomingCount[$dbId] = 0 }
                        $incomingCount[$dbId]++
                    }
                }
            }
        }
    }

    # Se houver blocos sem predecessores, liga na raiz para nao ficarem perdidos no diagrama.
    foreach ($nodeId in $nodeMap.Keys) {
        $label = $nodeMap[$nodeId]
        $isOb = $label.StartsWith("OB ")
        if ($isOb) { continue }
        $incoming = if ($incomingCount.ContainsKey($nodeId)) { [int]$incomingCount[$nodeId] } else { 0 }
        if ($incoming -eq 0) {
            $edgeKey = "ROOT|$nodeId"
            if ($edgeSet.Add($edgeKey)) {
                $lines.Add("  ROOT --> $nodeId")
            }
        }
    }

    # Declara todos os nos no fim para aplicar labels completos.
    foreach ($nodeId in $nodeMap.Keys) {
        $label = $nodeMap[$nodeId].Replace('"', "'")
        $lines.Add("  $nodeId[`"$label`"]")
    }

    # Paleta semantica por tipo de bloco.
    $lines.Add("  classDef ob fill:#7e57c2,color:#fff,stroke:#5e35b1;")
    $lines.Add("  classDef fb fill:#1e88e5,color:#fff,stroke:#1565c0;")
    $lines.Add("  classDef fc fill:#2e7d32,color:#fff,stroke:#1b5e20;")
    $lines.Add("  classDef db fill:#9e9e9e,color:#000,stroke:#757575;")

    foreach ($nodeId in $nodeMap.Keys) {
        $label = $nodeMap[$nodeId]
        if ($label.StartsWith("OB ")) { $lines.Add("  class $nodeId ob;") }
        elseif ($label.StartsWith("FB ")) { $lines.Add("  class $nodeId fb;") }
        elseif ($label.StartsWith("FC ")) { $lines.Add("  class $nodeId fc;") }
        elseif ($label.StartsWith("DB ")) { $lines.Add("  class $nodeId db;") }
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
            $scriptName = ([string]$json.script).Trim()

            # Lista de scripts permitidos por seguranca
            $allowedScripts = @(
                "RunExporterWithAttach.ps1",
                "Import-New-Blocks.ps1",
                "Run-Full-Cycle.ps1",
                "Generate-Documentation.ps1",
                "Run-TiaMap-Dev.ps1" # Novo script para iniciar o TIA Map
            )

            # Verifica se o script esta na lista permitida e se existe no disco
            if ($allowedScripts -contains $scriptName) {
                $possiblePaths = @(
                    (Join-Path $scriptRoot $scriptName),
                    (Join-Path $projectRoot $scriptName),
                    (Join-Path (Join-Path $projectRoot "Logs") $scriptName),
                    (Join-Path (Get-Location).Path $scriptName),
                    (Join-Path (Join-Path (Get-Location).Path "Logs") $scriptName)
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
                $debugPaths = @(
                    (Join-Path $scriptRoot $scriptName),
                    (Join-Path $projectRoot $scriptName),
                    (Join-Path (Join-Path $projectRoot "Logs") $scriptName)
                ) -join " | "
                $content = (@{
                    status = "error"
                    message = "Script nao permitido ou nao encontrado."
                    script = $scriptName
                    searched = $debugPaths
                } | ConvertTo-Json -Compress)
                $statusCode = 404
                $contentType = "application/json; charset=utf-8"
            }
        }
        # ROTA: Configuracao de caminho TIA (/api/project-path)
        elseif ($path -eq "/api/project-path" -and $method -eq "GET") {
            $resolvedPath = Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot
            $xmlCount = (Get-ChildItem -Path $resolvedPath -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
            $content = (@{
                status = "success"
                tiaPath = $selectedTiaPath
                resolvedExportPath = $resolvedPath
                xmlCount = $xmlCount
            } | ConvertTo-Json -Compress)
            $contentType = "application/json; charset=utf-8"
        }
        elseif ($path -eq "/api/project-path" -and $method -eq "POST") {
            $reader = [System.IO.StreamReader]::new($request.InputStream, [System.Text.Encoding]::UTF8)
            $body = $reader.ReadToEnd()
            $reader.Dispose()

            $json = $body | ConvertFrom-Json
            $candidatePath = ([string]$json.path).Trim()

            if ([string]::IsNullOrWhiteSpace($candidatePath) -or -not (Test-Path $candidatePath)) {
                $content = (@{ status = "error"; message = "Caminho invalido ou inexistente." } | ConvertTo-Json -Compress)
                $statusCode = 400
                $contentType = "application/json; charset=utf-8"
            } else {
                $selectedTiaPath = $candidatePath
                Save-WebSettings -TiaPath $selectedTiaPath

                $resolvedPath = Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot
                $xmlCount = (Get-ChildItem -Path $resolvedPath -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
                $content = (@{
                    status = "success"
                    message = "Caminho salvo com sucesso."
                    tiaPath = $selectedTiaPath
                    resolvedExportPath = $resolvedPath
                    xmlCount = $xmlCount
                } | ConvertTo-Json -Compress)
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
                if ($logContent -is [System.Array]) {
                    $logContent = ($logContent -join "`n")
                }
                if ($logContent -isnot [string]) {
                    $logContent = [string]$logContent
                }
                $content = (@{ log = $logContent } | ConvertTo-Json -Compress)
            } else {
                $content = (@{ log = "Nenhum log encontrado." } | ConvertTo-Json -Compress)
            }

            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Obter Diagrama Mermaid (/api/mermaid)
        elseif ($path -eq "/api/mermaid") {
            $resolvedPath = Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot
            $diagram = New-ProjectMermaid -ExportPath $resolvedPath
            $content = (@{ diagram = $diagram } | ConvertTo-Json -Compress)
            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Obter Diagrama de Execucao (/api/execution-mermaid)
        elseif ($path -eq "/api/execution-mermaid") {
            $resolvedPath = Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot
            $diagram = New-ExecutionMermaid -ExportPath $resolvedPath
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
