param(
    [string]$InputPath
)

$ErrorActionPreference = 'Stop'

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$defaultInput = Join-Path $scriptPath 'Logs\ControlModules_Export'
$inputPath = if (-not [string]::IsNullOrWhiteSpace($InputPath)) { $InputPath } else { $defaultInput }
$outputPath = Join-Path $scriptPath 'DocumentacaoDoProjeto.html'

Write-Host 'Iniciando gerador de documentacao...' -ForegroundColor Cyan
Write-Host ('Lendo de: ' + $inputPath)

if (-not (Test-Path $inputPath)) {
    throw 'Diretorio de entrada nao encontrado. Execute a exportacao primeiro.'
}

$xmlFiles = Get-ChildItem -Path $inputPath -Filter *.xml -Recurse -File
if ($xmlFiles.Count -eq 0) {
    throw 'Nenhum arquivo XML encontrado no diretorio de entrada.'
}

$blocks = @()
foreach ($file in $xmlFiles) {
    try {
        [xml]$xmlContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8

        $ns = New-Object System.Xml.XmlNamespaceManager($xmlContent.NameTable)
        $ns.AddNamespace('SI', 'http://www.siemens.com/automation/Openness/SW/Interface/v5')

        $blockName = $file.Name -replace '\.xml$',''
        $blockType = $xmlContent.DocumentElement.Name

        $authorNode = $xmlContent.SelectSingleNode('//DocumentInfo/CreatedBy')
        $author = if ($authorNode) { $authorNode.'#text' } else { 'N/A' }

        $versionNode = $xmlContent.SelectSingleNode("//SI:AttributeList/SI:Attribute[@Name='Version']", $ns)
        $version = if ($versionNode) { $versionNode.'#text' } else { '0.0' }

        $commentNode = $xmlContent.SelectSingleNode("(//SI:MultilingualText[@CompositionName='Comment']/SI:Val/SI:Text | //SI:MultilingualText[@CompositionName='Title']/SI:Val/SI:Text)[1]", $ns)
        $comment = if ($commentNode) { $commentNode.'#text' } else { 'Sem comentario.' }

        $blocks += [PSCustomObject]@{
            Nome       = $blockName
            Tipo       = $blockType
            Caminho    = $file.Directory.FullName.Replace($inputPath, '')
            Autor      = $author
            Versao     = $version
            Comentario = $comment
        }
    }
    catch {
        Write-Warning ('Falha ao processar arquivo ' + $file.Name + ': ' + $_)
    }
}

$htmlHeader = @"
<!DOCTYPE html>
<html lang='pt-BR'>
<head>
  <meta charset='UTF-8'>
  <title>Documentacao do Projeto</title>
  <style>
    body { font-family: Segoe UI, Arial, sans-serif; margin: 20px; background: #f4f4f9; color: #333; }
    h1 { color: #004669; border-bottom: 2px solid #009999; padding-bottom: 8px; }
    .summary { background: #e7f3fe; padding: 12px; border-left: 5px solid #2196F3; margin-bottom: 16px; }
    table { width: 100%; border-collapse: collapse; background: #fff; }
    th, td { padding: 10px; border-bottom: 1px solid #ddd; text-align: left; }
    thead { background: #004669; color: #fff; }
    .type-OB { color: #d32f2f; font-weight: bold; }
    .type-FB { color: #1976d2; font-weight: bold; }
    .type-FC { color: #388e3c; font-weight: bold; }
    .footer { margin-top: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <h1>Documentacao automatica dos blocos</h1>
  <div class='summary'><strong>Resumo:</strong> $($blocks.Count) blocos em <code>$inputPath</code>.</div>
  <table>
    <thead>
      <tr><th>Nome</th><th>Tipo</th><th>Autor</th><th>Versao</th><th>Comentario</th><th>Pasta</th></tr>
    </thead>
    <tbody>
"@

$htmlBody = ''
foreach ($block in ($blocks | Sort-Object Tipo, Nome)) {
    $cssClass = 'type-' + $block.Tipo
    $htmlBody += @"
      <tr>
        <td>$($block.Nome)</td>
        <td class='$cssClass'>$($block.Tipo)</td>
        <td>$($block.Autor)</td>
        <td>$($block.Versao)</td>
        <td>$($block.Comentario)</td>
        <td>$($block.Caminho)</td>
      </tr>
"@
}

$htmlFooter = @"
    </tbody>
  </table>
  <div class='footer'>Relatorio gerado em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss').</div>
</body>
</html>
"@

$finalHtml = $htmlHeader + $htmlBody + $htmlFooter
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outputPath, $finalHtml, $utf8NoBom)

Write-Host ('Sucesso. HTML gerado em: ' + $outputPath) -ForegroundColor Green
