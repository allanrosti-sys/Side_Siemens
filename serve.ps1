$port = 8000
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Servidor HTTP iniciado em http://localhost:$port/" -ForegroundColor Green
Write-Host "Abra seu navegador e acesse: http://localhost:$port/DocumentacaoDoProjeto.html" -ForegroundColor Cyan
Write-Host "Pressione CTRL+C para parar o servidor" -ForegroundColor Yellow

while($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    
    $filePath = $request.Url.LocalPath
    if ($filePath -eq "/") { $filePath = "/DocumentacaoDoProjeto.html" }
    
    $fullPath = Join-Path (Get-Location).Path $filePath.TrimStart("/")
    
    if (Test-Path $fullPath) {
        $content = [System.IO.File]::ReadAllBytes($fullPath)
        $response.ContentType = if ($fullPath -match "\.html$") { "text/html; charset=utf-8" } else { "text/plain" }
        $response.OutputStream.Write($content, 0, $content.Length)
        $response.StatusCode = 200
    } else {
        $response.StatusCode = 404
        $textWriter = New-Object System.IO.StreamWriter($response.OutputStream)
        $textWriter.Write("404 - Arquivo nao encontrado")
        $textWriter.Flush()
    }
    $response.OutputStream.Close()
}
