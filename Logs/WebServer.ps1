# Script: WebServer.ps1
# Objetivo: Servidor Web para controlar automacao TIA e visualizar estrutura do projeto.
# Autor: Equipe de IAs (Gemini/Copilot/Codex)
# Data: 2026-03-02

param(
    [int]$Port = 8099
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
$selectedVendor = "auto"

# Carrega o ultimo caminho de projeto configurado a partir de um arquivo JSON.
if (Test-Path $settingsFile) {
    try {
        $settings = Get-Content -Path $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($settings.tiaPath) {
            $selectedTiaPath = [string]$settings.tiaPath
        }
        if ($settings.vendor) {
            $selectedVendor = ([string]$settings.vendor).ToLowerInvariant()
        }
    } catch {
        Write-Warning "Falha ao ler web_settings.json: $($_.Exception.Message)"
    }
}

# Salva o caminho do projeto selecionado no arquivo de configuracao JSON.
function Save-WebSettings {
    param(
        [string]$TiaPath,
        [string]$Vendor,
        [int]$Port
    )
    $normalizedVendor = if ([string]::IsNullOrWhiteSpace($Vendor)) { "auto" } else { $Vendor.ToLowerInvariant() }
    $existing = $null
    if (Test-Path $settingsFile) {
        try {
            $existing = Get-Content -Path $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            $existing = $null
        }
    }
    $effectivePort = if ($Port) { $Port } elseif ($existing -and $existing.port) { [int]$existing.port } else { $null }
    $obj = @{
        tiaPath = $TiaPath
        vendor = $normalizedVendor
    }
    if ($effectivePort) {
        $obj.port = $effectivePort
    }
    $json = $obj | ConvertTo-Json -Compress
    Set-Content -Path $settingsFile -Value $json -Encoding UTF8
}

# Atualiza o arquivo de configuracao com a porta atual para auxiliar scripts auxiliares.
Save-WebSettings -TiaPath $selectedTiaPath -Vendor $selectedVendor -Port $Port

# Detecta o vendor efetivo do projeto com base na selecao do usuario ou na origem.
function Get-ProjectVendor {
    param(
        [string]$BasePath,
        [string]$ConfiguredVendor
    )

    $normalizedVendor = if ([string]::IsNullOrWhiteSpace($ConfiguredVendor)) { "auto" } else { $ConfiguredVendor.ToLowerInvariant() }
    if ($normalizedVendor -in @("siemens", "rockwell")) {
        return $normalizedVendor
    }

    if (-not [string]::IsNullOrWhiteSpace($BasePath) -and (Test-Path $BasePath)) {
        $item = Get-Item -LiteralPath $BasePath -ErrorAction SilentlyContinue
        if ($item -and -not $item.PSIsContainer) {
            $ext = $item.Extension.ToLowerInvariant()
            if ($ext -in @(".l5x", ".l5k")) { return "rockwell" }
            if ($ext -in @(".ap20", ".ap19")) { return "siemens" }
        } else {
            $hasL5x = Get-ChildItem -Path $BasePath -Include *.L5X, *.l5k -File -Recurse -Depth 1 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hasL5x) { return "rockwell" }

            $hasSiemensProject = Get-ChildItem -Path $BasePath -Include *.ap20, *.ap19, *.xml -File -Recurse -Depth 1 -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -in @(".ap20", ".ap19") -or $_.BaseName -match '^(OB|FB|FC|DB)_' } |
                Select-Object -First 1
            if ($hasSiemensProject) { return "siemens" }
        }
    }

    return "auto"
}

# Funcao para sanitizar texto para uso em labels do Mermaid.
function Sanitize-MermaidLabel([string]$label) {
    if ([string]::IsNullOrWhiteSpace($label)) { return '""' }
    # Substitui aspas duplas por uma entidade e envolve o resultado em aspas para o Mermaid.
    $sanitized = $label.Replace('"', '#quot;')
    return "`"$sanitized`""
}

# Resolve o caminho correto da pasta de exportacao de XMLs, testando varios locais possiveis.
function Resolve-ExportPath {
    param([string]$BasePath, [string]$FallbackPath)

    $candidates = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($BasePath)) {
        $candidates.Add((Join-Path $BasePath "Logs\\ControlModules_Export"))
        $candidates.Add((Join-Path $BasePath "ControlModules_Export"))
        # Permite usar a pasta diretamente quando o usuario apontar ja para ControlModules_Export.
        $candidates.Add($BasePath)
    }
    $candidates.Add($FallbackPath)

    # Funcao interna para contar apenas XMLs de blocos validos (OB, FB, FC).
    function Get-BlockXmlCount([string]$candidatePath) {
        $blockFiles = Get-ChildItem -Path $candidatePath -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.BaseName -match '^(OB|FB|FC)_' }
        return ($blockFiles | Measure-Object).Count
    }

    $firstExisting = $null
    foreach ($candidate in $candidates) {
        if (-not (Test-Path $candidate)) { continue }
        if (-not $firstExisting) { $firstExisting = $candidate }
        $blockCount = Get-BlockXmlCount $candidate
        if ($blockCount -gt 0) { return $candidate }
    }

    if ($firstExisting) { return $firstExisting }
    return $FallbackPath
}

# Resolve o arquivo Rockwell (.L5X ou .L5K) a partir da origem informada.
function Resolve-RockwellSource {
    param([string]$BasePath)

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        return @{
            status = "error"
            message = "Caminho vazio para origem Rockwell."
            path = $null
        }
    }

    if (-not (Test-Path $BasePath)) {
        return @{
            status = "error"
            message = "Caminho informado nao existe."
            path = $null
        }
    }

    $item = Get-Item -LiteralPath $BasePath -ErrorAction SilentlyContinue
    if (-not $item) {
        return @{
            status = "error"
            message = "Nao foi possivel abrir a origem selecionada."
            path = $null
        }
    }

    if (-not $item.PSIsContainer) {
        $ext = $item.Extension.ToLowerInvariant()
        if ($ext -in @(".l5x", ".l5k")) {
            return @{
                status = "success"
                message = "Arquivo Rockwell detectado."
                path = $item.FullName
                extension = $ext
            }
        }
        return @{
            status = "error"
            message = "Arquivo nao suportado para Rockwell. Use .L5X ou .L5K."
            path = $item.FullName
        }
    }

    $candidate = Get-ChildItem -Path $item.FullName -Include *.L5X, *.l5k -File -Recurse -Depth 2 -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($candidate) {
        return @{
            status = "success"
            message = "Arquivo Rockwell encontrado na pasta."
            path = $candidate.FullName
            extension = $candidate.Extension.ToLowerInvariant()
        }
    }

    return @{
        status = "error"
        message = "Nenhum arquivo .L5X ou .L5K encontrado na pasta selecionada."
        path = $null
    }
}

# --- FUNCAO: GERAR DIAGRAMA MERMAID (SIEMENS) ---
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
        $xmlCount = (Get-ChildItem -Path $dir.FullName -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        $label = "$($dir.Name) ($xmlCount)"
        $sanitizedLabel = Sanitize-MermaidLabel -label $label
        $lines.Add("  ROOT --> $node[$sanitizedLabel]")
    }

    # Expande estrutura de blocos (limitado para evitar diagrama gigante).
    $maxBlockNodes = 180
    $blockFiles = $allXml | Sort-Object FullName | Select-Object -First $maxBlockNodes
    $folderNodes = @{}
    $bIndex = 0
    foreach ($file in $blockFiles) {
        $relativeFolder = (Split-Path -Parent ($file.FullName.Replace($ExportPath, "").TrimStart('\'))).Trim()
        if ([string]::IsNullOrWhiteSpace($relativeFolder)) { $relativeFolder = "raiz" }

        if (-not $folderNodes.ContainsKey($relativeFolder)) {
            $folderId = "F$($folderNodes.Count + 1)"
            $folderNodes[$relativeFolder] = $folderId
            $sanitizedFolder = Sanitize-MermaidLabel -label $relativeFolder.Replace('\', '/')
            $lines.Add("  ROOT --> $folderId[$sanitizedFolder]")
        }

        $bIndex++
        $blockId = "B$bIndex"
        $base = $file.BaseName
        $label = if ($base.Length -gt 42) { $base.Substring(0, 42) + "..." } else { $base }
        $sanitizedBlockLabel = Sanitize-MermaidLabel -label $label
        $lines.Add("  $($folderNodes[$relativeFolder]) --> $blockId[$sanitizedBlockLabel]")
    }

    if ($allXml.Count -gt $maxBlockNodes) {
        $remaining = $allXml.Count - $maxBlockNodes
        $lines.Add("  ROOT --> MORE[`"... +$remaining blocos nao exibidos no mapa estrutural`"]")
    }

    return ($lines -join "`n")
}

# --- FUNCAO: GERAR DIAGRAMA DE EXECUCAO (CALL GRAPH - SIEMENS) ---
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

    # Funcao interna para criar um ID seguro para nos do Mermaid.
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

    # Itera sobre cada arquivo XML para extrair informacoes de chamada.
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
        $label = $nodeMap[$nodeId]
        $sanitizedLabel = Sanitize-MermaidLabel -label $label
        $lines.Add("  $nodeId[$sanitizedLabel]")
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

# --- FUNCAO: GERAR DIAGRAMA DE ESTRUTURA/EXECUCAO (ROCKWELL L5K) ---
# Le um arquivo L5K e monta um fluxo de chamadas entre Programas e Rotinas.
function New-RockwellMermaid {
    param(
        [Alias("L5xPath")]
        [string]$L5kPath
    )
    
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("graph TD")
    $lines.Add("  classDef program fill:#c2185b,color:#fff,stroke:#ad1457,stroke-width:2px;")
    $lines.Add("  classDef routine fill:#2e7d32,color:#fff,stroke:#256a2a,stroke-width:2px;")
    $lines.Add("  classDef callout fill:#f5f5f5,color:#333,stroke:#ccc;")
    
    # Funcao interna para criar um ID seguro para nos do Mermaid.
    function Get-SafeId([string]$text) {
        if ([string]::IsNullOrWhiteSpace($text)) { return "N_EMPTY" }
        $safe = ($text -replace '[^A-Za-z0-9_]', '_')
        if ($safe -match '^[0-9]') { $safe = "N_$safe" }
        return "N_$safe"
    }

    if (-not (Test-Path $L5kPath)) {
        $lines.Add("  ROOT((Arquivo L5K nao encontrado))")
        return ($lines -join "`n")
    }

    try {
        $fileContent = Get-Content -Path $L5kPath -Raw
        $extension = ([System.IO.Path]::GetExtension($L5kPath)).ToLowerInvariant()
        if ($extension -eq ".l5x") {
            $lines.Add("  ROOT((Arquivo L5X detectado))")
            $lines.Add("  ROOT --> INFO[`"L5X requer parser XML dedicado. Use o Puchta PLC Insight para analise completa.`"]")
            return ($lines -join "`n")
        }
        
        # Regex para encontrar o nome do Controller
        $controllerName = "Rockwell Project"
        $controllerMatch = [regex]::Match($fileContent, 'CONTROLLER\s+([\w-]+)')
        if ($controllerMatch.Success) {
            $controllerName = $controllerMatch.Groups[1].Value
        }
        $rootId = Get-SafeId -text $controllerName
        $lines.Add("  $rootId[($controllerName)]")
        $lines.Add("  class $rootId callout;")

        # Regex para encontrar todos os programas e suas rotinas
        $programPattern = 'PROGRAM\s+([\w-]+)(.*?)\bEND_PROGRAM\b'
        $programMatches = [regex]::Matches($fileContent, $programPattern, "Singleline")

        foreach ($pMatch in $programMatches) {
            $progName = $pMatch.Groups[1].Value
            $progId = Get-SafeId -text $progName
            $progLabel = Sanitize-MermaidLabel -label $progName
            
            $lines.Add("  $rootId --> $progId{$progLabel}")
            $lines.Add("  class $progId program;")

            $programContent = $pMatch.Groups[2].Value
            $routinePattern = 'ROUTINE\s+([\w-]+)(.*?)\bEND_ROUTINE\b'
            $routineMatches = [regex]::Matches($programContent, $routinePattern, "Singleline")

            foreach ($rMatch in $routineMatches) {
                $routName = $rMatch.Groups[1].Value
                $routId = Get-SafeId -text "${progName}_${routName}"
                $routLabel = Sanitize-MermaidLabel -label $routName
                
                $lines.Add("  $progId --> $routId[$routLabel]")
                $lines.Add("  class $routId routine;")
                
                $routineContent = $rMatch.Groups[2].Value
                
                # Regex para capturar JSR(NomeRotina)
                $jsrPattern = 'JSR\s*\(\s*([\w-]+)'
                $jsrMatches = [regex]::Matches($routineContent, $jsrPattern, "IgnoreCase")
                
                foreach ($jsrMatch in $jsrMatches) {
                    $targetName = $jsrMatch.Groups[1].Value
                    $targetId = Get-SafeId -text "${progName}_${targetName}"
                    $lines.Add("  $routId -.-> $targetId")
                }
            }
        }

    } catch {
        $lines.Add("  ERR[Erro no parse L5K: $($_.Exception.Message)]")
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
        # ROTEAMENTO: Decide qual acao tomar com base no caminho da URL.
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
        # ROTA: Documento HTML gerado (Siemens ou Rockwell conforme URL)
        elseif ($path -eq "/DocumentacaoDoProjeto.html") {
            $docCandidates = @(
                (Join-Path $projectRoot "DocumentacaoDoProjeto.html"),
                (Join-Path $scriptRoot "DocumentacaoDoProjeto.html")
            )
            $docPath = $docCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($docPath) {
                $content = [System.IO.File]::ReadAllText($docPath, [System.Text.Encoding]::UTF8)
            } else {
                $content = "<h1>Documentacao Siemens ainda nao gerada.</h1><p>Use o botao 4 para gerar.</p>"
                $statusCode = 404
            }
        }
        elseif ($path -eq "/DocumentacaoRockwell.html") {
            $docCandidates = @(
                (Join-Path $projectRoot "DocumentacaoRockwell.html"),
                (Join-Path $scriptRoot "DocumentacaoRockwell.html")
            )
            $docPath = $docCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($docPath) {
                $content = [System.IO.File]::ReadAllText($docPath, [System.Text.Encoding]::UTF8)
            } else {
                $content = "<h1>Documentacao Rockwell ainda nao gerada.</h1><p>Use o botao 4 para gerar.</p>"
                $statusCode = 404
            }
        }
        # ROTA: Versao/capacidades da API
        elseif ($path -eq "/api/version") {
            $content = (@{
                status = "success"
                version = "2026.03.05"
                port = $Port
                capabilities = @(
                    "run-scripts",
                    "project-path",
                    "vendor-selection",
                    "mermaid-structure",
                    "mermaid-execution",
                    "documentation-popup"
                )
            } | ConvertTo-Json -Compress)
            $contentType = "application/json; charset=utf-8"
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
                "Generate-Documentation-Rockwell.ps1",
                "Run-TiaMap-Dev.ps1"
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

            $skipExecution = $false
            if ($targetScript) {
                # Preparar argumentos baseados no caminho configurado e no vendor efetivo.
                $scriptArgs = @()
                $effectiveVendor = Get-ProjectVendor -BasePath $selectedTiaPath -ConfiguredVendor $selectedVendor
                $resolvedFromSelection = if ($effectiveVendor -eq "siemens") { Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot } else { $null }
                $rockwellSource = if ($effectiveVendor -eq "rockwell") { Resolve-RockwellSource -BasePath $selectedTiaPath } else { $null }
                if (-not [string]::IsNullOrWhiteSpace($selectedTiaPath) -and (Test-Path $selectedTiaPath)) {
                    Write-Host "DEBUG: Caminho TIA configurado: '$selectedTiaPath'" -ForegroundColor DarkGray

                    if ($scriptName -eq "RunExporterWithAttach.ps1") {
                        # Busca recursiva limitada para encontrar o .ap20 caso esteja em subpasta
                        $ap20 = Get-ChildItem -Path $selectedTiaPath -Filter *.ap20 -File -Recurse -Depth 1 | Select-Object -First 1
                        if ($ap20) {
                            $exportDir = Join-Path $selectedTiaPath "Logs\ControlModules_Export"
                            $scriptArgs = @("-TargetProject", $ap20.FullName, "-TargetExport", $exportDir)
                            Write-Host ("DEBUG: Exporter Args: " + ($scriptArgs -join " ")) -ForegroundColor DarkGray
                        } else {
                            Write-Warning "ALERTA: Nenhum arquivo .ap20 encontrado em '$selectedTiaPath'"
                        }
                    }
                    elseif ($scriptName -eq "Generate-Documentation.ps1") {
                        if ($effectiveVendor -eq "rockwell") {
                            $rockwellDoc = "Generate-Documentation-Rockwell.ps1"
                            $possibleRockwell = @(
                                (Join-Path $scriptRoot $rockwellDoc),
                                (Join-Path $projectRoot $rockwellDoc),
                                (Join-Path (Join-Path $projectRoot "Logs") $rockwellDoc)
                            )
                            $rockwellScript = $possibleRockwell | Where-Object { Test-Path $_ } | Select-Object -First 1
                            if ($rockwellScript) {
                                $targetScript = $rockwellScript
                                $scriptName = $rockwellDoc
                                $scriptArgs = @("-InputPath", $selectedTiaPath)
                            } else {
                                $content = (@{
                                    status = "error"
                                    message = "Script de documentacao Rockwell nao encontrado."
                                } | ConvertTo-Json -Compress)
                                $statusCode = 500
                                $contentType = "application/json; charset=utf-8"
                                $skipExecution = $true
                            }
                        }
                        if ($resolvedFromSelection -and (Test-Path $resolvedFromSelection)) {
                            $scriptArgs = @("-InputPath", $resolvedFromSelection)
                            Write-Host ("DEBUG: Doc Args: " + ($scriptArgs -join " ")) -ForegroundColor DarkGray
                        }
                    }
                    elseif ($scriptName -eq "Run-TiaMap-Dev.ps1") {
                        if ($effectiveVendor -eq "rockwell") {
                            if ($rockwellSource -and $rockwellSource.status -eq "success" -and (Test-Path $rockwellSource.path)) {
                                $scriptArgs = @("-DataPath", $rockwellSource.path)
                                Write-Host ("DEBUG: TIA Map Args (Rockwell): " + ($scriptArgs -join " ")) -ForegroundColor DarkGray
                            }
                        } else {
                            if ($resolvedFromSelection -and (Test-Path $resolvedFromSelection)) {
                                $scriptArgs = @("-DataPath", $resolvedFromSelection)
                                Write-Host ("DEBUG: TIA Map Args: " + ($scriptArgs -join " ")) -ForegroundColor DarkGray
                            }
                        }
                    }
                    elseif ($scriptName -eq "Import-New-Blocks.ps1") {
                        # Verifica se o frontend enviou caminho de origem especifico e resolve projeto alvo.
                        $sourcePath = if ($json.sourcePath) { [string]$json.sourcePath } else { "" }
                        $targetAp20 = Get-ChildItem -Path $selectedTiaPath -Filter *.ap20 -File -Recurse -Depth 1 -ErrorAction SilentlyContinue | Select-Object -First 1
                        if ($sourcePath -and (Test-Path $sourcePath)) {
                            $scriptArgs = @("-SourcePath", $sourcePath)
                        }
                        if ($targetAp20) {
                            $scriptArgs += @("-TargetProjectPath", $targetAp20.FullName)
                        }
                        if ($scriptArgs.Count -gt 0) {
                            Write-Host ("DEBUG: Import Args: " + ($scriptArgs -join " ")) -ForegroundColor DarkGray
                        }
                    }
                }

                if (-not $skipExecution) {
                    Write-Host ("Executando: " + $scriptName + " " + ($scriptArgs -join " ")) -ForegroundColor Yellow
                }

                if ($skipExecution) {
                    # Retorna o erro definido anteriormente sem executar script.
                }
                elseif ($scriptName -eq "Generate-Documentation.ps1" -or $scriptName -eq "Generate-Documentation-Rockwell.ps1") {
                    # Para documentacao, retorna URL final para o frontend abrir popup.
                    if ($scriptArgs.Count -gt 0) {
                        powershell -ExecutionPolicy Bypass -File $targetScript @scriptArgs | Out-Null
                    } else {
                        powershell -ExecutionPolicy Bypass -File $targetScript | Out-Null
                    }

                    $docGenerated = $null
                    if ($scriptName -eq "Generate-Documentation-Rockwell.ps1") {
                        $rockwellCandidates = @(
                            (Join-Path $projectRoot "DocumentacaoRockwell.html"),
                            (Join-Path $scriptRoot "DocumentacaoRockwell.html")
                        )
                        $docGenerated = $rockwellCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
                    } else {
                        $siemensCandidates = @(
                            (Join-Path $projectRoot "DocumentacaoDoProjeto.html"),
                            (Join-Path $scriptRoot "DocumentacaoDoProjeto.html")
                        )
                        $docGenerated = $siemensCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
                    }

                    if ($docGenerated) {
                        $docName = Split-Path -Leaf $docGenerated
                        $content = (@{
                            status = "success"
                            message = "Documentacao gerada com sucesso."
                            docUrl = "/$docName"
                        } | ConvertTo-Json -Compress)
                    } else {
                        $content = (@{
                            status = "error"
                            message = "Script executado, mas o HTML nao foi encontrado."
                        } | ConvertTo-Json -Compress)
                        $statusCode = 500
                    }
                } else {
                    # Cria um arquivo de log unico para este job.
                    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                    $logFileName = "run_log_{$timestamp}.txt"
                    $logFilePath = Join-Path $scriptRoot $logFileName
                    
                    # Inicia o script em job separado e redireciona toda a saida para o arquivo de log.
                    Start-Job -ScriptBlock {
                        param($target, $arguments, $log)
                        # O operador '&' executa o comando/script, e '@' faz o "splatting" do array de argumentos.
                        & $target @arguments *>&1 | Out-File -FilePath $log -Encoding utf8
                    } -ArgumentList $targetScript, $scriptArgs, $logFilePath | Out-Null

                    $content = (@{ 
                        status = "success"; 
                        message = "Script iniciado em background.";
                        logPath = $logFilePath
                    } | ConvertTo-Json -Compress)
                }
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
            $detectedVendor = Get-ProjectVendor -BasePath $selectedTiaPath -ConfiguredVendor $selectedVendor
            if ($detectedVendor -eq "rockwell") {
                $rockwellSource = Resolve-RockwellSource -BasePath $selectedTiaPath
                $content = (@{
                    status = "success"
                    tiaPath = $selectedTiaPath
                    vendor = $selectedVendor
                    detectedVendor = $detectedVendor
                    rockwellSource = $rockwellSource.path
                    rockwellStatus = $rockwellSource.message
                    resolvedExportPath = $null
                    xmlCount = 0
                } | ConvertTo-Json -Compress)
            } else {
                $resolvedPath = Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot
                $xmlCount = (Get-ChildItem -Path $resolvedPath -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
                $content = (@{
                    status = "success"
                    tiaPath = $selectedTiaPath
                    vendor = $selectedVendor
                    detectedVendor = $detectedVendor
                    resolvedExportPath = $resolvedPath
                    xmlCount = $xmlCount
                } | ConvertTo-Json -Compress)
            }
            $contentType = "application/json; charset=utf-8"
        }
        elseif ($path -eq "/api/project-path" -and $method -eq "POST") {
            $reader = [System.IO.StreamReader]::new($request.InputStream, [System.Text.Encoding]::UTF8)
            $body = $reader.ReadToEnd()
            $reader.Dispose()

            $json = $body | ConvertFrom-Json
            $candidatePath = ([string]$json.path).Trim()
            $candidateVendor = if ($json.vendor) { ([string]$json.vendor).Trim().ToLowerInvariant() } else { "auto" }

            if ($candidateVendor -notin @("auto", "siemens", "rockwell")) {
                $candidateVendor = "auto"
            }

            if ([string]::IsNullOrWhiteSpace($candidatePath) -or -not (Test-Path $candidatePath)) {
                $content = (@{ status = "error"; message = "Caminho invalido ou inexistente." } | ConvertTo-Json -Compress)
                $statusCode = 400
                $contentType = "application/json; charset=utf-8"
            } else {
                $selectedTiaPath = $candidatePath
                $selectedVendor = $candidateVendor
                Save-WebSettings -TiaPath $selectedTiaPath -Vendor $selectedVendor -Port $Port

                $detectedVendor = Get-ProjectVendor -BasePath $selectedTiaPath -ConfiguredVendor $selectedVendor
                if ($detectedVendor -eq "rockwell") {
                    $rockwellSource = Resolve-RockwellSource -BasePath $selectedTiaPath
                    $content = (@{
                        status = "success"
                        message = "Caminho salvo com sucesso."
                        tiaPath = $selectedTiaPath
                        vendor = $selectedVendor
                        detectedVendor = $detectedVendor
                        rockwellSource = $rockwellSource.path
                        rockwellStatus = $rockwellSource.message
                        resolvedExportPath = $null
                        xmlCount = 0
                    } | ConvertTo-Json -Compress)
                } else {
                    $resolvedPath = Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot
                    $xmlCount = (Get-ChildItem -Path $resolvedPath -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
                    $content = (@{
                        status = "success"
                        message = "Caminho salvo com sucesso."
                        tiaPath = $selectedTiaPath
                        vendor = $selectedVendor
                        detectedVendor = $detectedVendor
                        resolvedExportPath = $resolvedPath
                        xmlCount = $xmlCount
                    } | ConvertTo-Json -Compress)
                }
                $contentType = "application/json; charset=utf-8"
            }
        }
        # ROTA: Obter Logs (/api/logs)
        elseif ($path -eq "/api/logs") {
            $logPath = $request.QueryString["logPath"]
            if ([string]::IsNullOrWhiteSpace($logPath)) {
                # Sem logPath: retorna o ultimo log conhecido para facilitar a UX.
                $latest = Get-ChildItem -Path $scriptRoot -Filter "run_log_*.txt" -File -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
                if ($latest) {
                    $logContent = Get-Content -Path $latest.FullName -Raw -Encoding UTF8
                    $content = (@{ log = $logContent } | ConvertTo-Json -Compress)
                } else {
                    $content = (@{ log = "Nenhum log encontrado ainda." } | ConvertTo-Json -Compress)
                }
            } elseif (Test-Path $logPath) {
                $logContent = Get-Content -Path $logPath -Raw -Encoding UTF8
                $content = (@{ log = $logContent } | ConvertTo-Json -Compress)
            } else {
                $content = (@{ log = "Arquivo de log nao especificado ou nao encontrado." } | ConvertTo-Json -Compress)
            }
            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Diagnostico de Cobertura (/api/coverage)
        elseif ($path -eq "/api/coverage") {
            $resolvedPath = Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot
            
            $stats = @{
                path = $resolvedPath
                total = 0
                valid = 0
                types = @{ OB=0; FB=0; FC=0; DB=0 }
                rejected = @()
            }

            if (Test-Path $resolvedPath) {
                $files = Get-ChildItem -Path $resolvedPath -Filter *.xml -File -Recurse -ErrorAction SilentlyContinue
                $stats.total = $files.Count
                
                foreach ($f in $files) {
                    if ($f.Length -gt 0) {
                        $stats.valid++
                        if ($f.Name -match '^OB') { $stats.types.OB++ }
                        elseif ($f.Name -match '^FB') { $stats.types.FB++ }
                        elseif ($f.Name -match '^FC') { $stats.types.FC++ }
                        elseif ($f.Name -match '^DB') { $stats.types.DB++ }
                    } else {
                        $stats.rejected += $f.Name
                    }
                }
            }
            
            $content = ($stats | ConvertTo-Json -Compress -Depth 3)
            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Obter Diagrama Mermaid (/api/mermaid)
        elseif ($path -eq "/api/mermaid") {
            $effectiveVendor = Get-ProjectVendor -BasePath $selectedTiaPath -ConfiguredVendor $selectedVendor

            if ($effectiveVendor -eq "rockwell") {
                $rockwellSource = Resolve-RockwellSource -BasePath $selectedTiaPath
                if ($rockwellSource.status -eq "success") {
                    $diagram = New-RockwellMermaid -L5kPath $rockwellSource.path
                } else {
                    $diagram = "graph TD; ERROR[`"Erro: $($rockwellSource.message)`"];"
                }
            } else {
                $resolvedPath = Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot
                $diagram = New-ProjectMermaid -ExportPath $resolvedPath
            }
            $content = (@{ diagram = $diagram } | ConvertTo-Json -Compress)
            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Obter Diagrama de Execucao (/api/execution-mermaid)
        elseif ($path -eq "/api/execution-mermaid") {
            $effectiveVendor = Get-ProjectVendor -BasePath $selectedTiaPath -ConfiguredVendor $selectedVendor

            if ($effectiveVendor -eq "rockwell") {
                $rockwellSource = Resolve-RockwellSource -BasePath $selectedTiaPath
                if ($rockwellSource.status -eq "success") {
                    $diagram = New-RockwellMermaid -L5kPath $rockwellSource.path
                } else {
                    $diagram = "graph TD; ERROR[`"Erro: $($rockwellSource.message)`"];"
                }
            } else {
                $resolvedPath = Resolve-ExportPath -BasePath $selectedTiaPath -FallbackPath $exportRoot
                $diagram = New-ExecutionMermaid -ExportPath $resolvedPath
            }
            $content = (@{ diagram = $diagram } | ConvertTo-Json -Compress)
            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Inicia o seletor de pastas para o projeto (assincrono).
        elseif ($path -eq "/api/browse-project") {
            # Dispara script dedicado em processo separado para abrir o dialogo no desktop do usuario.
            $selectorScript = Join-Path $scriptRoot "Select-ProjectPath.ps1"
            if (Test-Path $selectorScript) {
                $args = @(
                    "-NoProfile",
                    "-ExecutionPolicy", "Bypass",
                    "-File", $selectorScript,
                    "-Port", $Port
                )
                Start-Process powershell -WorkingDirectory $scriptRoot -ArgumentList $args | Out-Null
                $content = (@{ status = "pending"; message = "Dialogo de selecao de pasta iniciado." } | ConvertTo-Json -Compress)
                $statusCode = 202 # Accepted
            } else {
                $content = (@{ status = "error"; message = "Select-ProjectPath.ps1 nao encontrado." } | ConvertTo-Json -Compress)
                $statusCode = 500
            }
            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Inicia o seletor de pastas para importacao (assincrono).
        elseif ($path -eq "/api/browse-import") {
            # Dispara script dedicado em processo separado para abrir o dialogo no desktop do usuario.
            $selectorScript = Join-Path $scriptRoot "Select-ImportPath.ps1"
            if (Test-Path $selectorScript) {
                $args = @(
                    "-NoProfile",
                    "-ExecutionPolicy", "Bypass",
                    "-File", $selectorScript
                )
                Start-Process powershell -WorkingDirectory $scriptRoot -ArgumentList $args | Out-Null
                $content = (@{ status = "pending"; message = "Dialogo de selecao de pasta iniciado." } | ConvertTo-Json -Compress)
                $statusCode = 202 # Accepted
            } else {
                $content = (@{ status = "error"; message = "Select-ImportPath.ps1 nao encontrado." } | ConvertTo-Json -Compress)
                $statusCode = 500
            }
            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Obtem o resultado do seletor de importacao e limpa o arquivo temporario.
        elseif ($path -eq "/api/get-import-path") {
            $tmpFile = Join-Path $scriptRoot "import_path.tmp"
            if (Test-Path $tmpFile) {
                # Se o arquivo temporario existe, le o caminho, apaga o arquivo e retorna sucesso.
                try {
                    $selectedPath = Get-Content -Path $tmpFile -Raw -Encoding UTF8
                    Remove-Item -Path $tmpFile -Force -ErrorAction Stop
                    $content = (@{ status = "success"; path = $selectedPath } | ConvertTo-Json -Compress)
                } catch {
                    $content = (@{ status = "error"; message = "Falha ao ler arquivo temporario." } | ConvertTo-Json -Compress)
                }
            } else {
                # Se o arquivo nao existe, significa que o usuario ainda nao selecionou.
                $content = (@{ status = "not_ready" } | ConvertTo-Json -Compress)
            }
            $contentType = "application/json; charset=utf-8"
        }
        # ROTA: Reinicia o proprio servidor web para aplicar alteracoes de codigo.
        # ROTA: Reiniciar Servidor (/api/restart)
        elseif ($path -eq "/api/restart") {
            $content = (@{ status = "success"; message = "Reiniciando servidor..." } | ConvertTo-Json -Compress)
            $contentType = "application/json; charset=utf-8"
            
            # Envia resposta antes de fechar
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = $contentType
            $response.StatusCode = 200
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.OutputStream.Close()
            
            # Inicia o script de startup (que mata este processo e sobe um novo)
            $startScript = Join-Path $scriptRoot "Start-WebPanel.ps1"
            Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$startScript`" -Port $Port"
            
            $listener.Stop()
            exit
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
