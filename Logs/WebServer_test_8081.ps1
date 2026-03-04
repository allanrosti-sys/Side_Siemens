# Script: WebServer.ps1
# Objetivo: Servidor Web simples para controlar a automação TIA via navegador.

$port = 8081
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "🌐 Servidor Web iniciado em http://localhost:$port/" -ForegroundColor Cyan
Write-Host "Pressione Ctrl+C para parar."

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptRoot

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
        if ($path -eq "/" -or $path -eq "/index.html") {
            # Serve a página principal
            $htmlPath = Join-Path $scriptRoot "index.html"
            if (Test-Path $htmlPath) {
                $content = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
            } else {
                $content = "<h1>Erro: index.html não encontrado</h1>"
                $statusCode = 404
            }
        }
        elseif ($path -eq "/api/run" -and $method -eq "POST") {
            # API para executar scripts
            $body = [System.IO.StreamReader]::new($request.InputStream).ReadToEnd()
            $json = $body | ConvertFrom-Json
            $scriptName = $json.script
            
            # Procura o script na pasta Logs ou na Raiz do projeto
            $possiblePaths = @(
                (Join-Path $scriptRoot $scriptName),
                (Join-Path $projectRoot $scriptName)
            )
            $targetScript = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
            
            if ($targetScript) {
                Write-Host "🚀 Executando: $scriptName" -ForegroundColor Yellow
                
                # Executa o script em um job separado para não travar o servidor
                Start-Job -ScriptBlock {
                    param($s)
                    powershell -ExecutionPolicy Bypass -File $s
                } -ArgumentList $targetScript | Out-Null
                
                $content = '{ "status": "success", "message": "Script iniciado em background." }'
                $contentType = "application/json"
            } else {
                $content = '{ "status": "error", "message": "Script não encontrado." }'
                $statusCode = 404
                $contentType = "application/json"
            }
        }
        elseif ($path -eq "/api/logs") {
            # API para ler logs recentes
            $logFiles = Get-ChildItem $scriptRoot -Filter "run_output_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($logFiles) {
                $logContent = Get-Content $logFiles.FullName -Raw
                # Escapar caracteres para JSON simples
                $safeLog = $logContent -replace '\\', '\\' -replace '"', '\"' -replace "`r`n", '\n'
                $content = "{ `"log`": `"$safeLog`" }"
            } else {
                $content = '{ "log": "Nenhum log encontrado." }'
            }
            $contentType = "application/json"
        }
        else {
            $content = "404 - Não encontrado"
            $statusCode = 404
        }
    }
    catch {
        $content = "500 - Erro Interno: $_"
        $statusCode = 500
        Write-Error $_
    }

    $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
    $response.ContentLength64 = $buffer.Length
    $response.ContentType = $contentType
    $response.StatusCode = $statusCode
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.Close()
}

