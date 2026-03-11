param(
    [string]$InputPath
)

$ErrorActionPreference = 'Stop'

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$settingsPath = Join-Path $scriptPath 'Logs\web_settings.json'
$outputPath = Join-Path $scriptPath 'DocumentacaoRockwell.html'

function Resolve-RockwellFile {
    param([string]$BasePath)

    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        return $null
    }

    if (-not (Test-Path $BasePath)) {
        return $null
    }

    $item = Get-Item -LiteralPath $BasePath -ErrorAction SilentlyContinue
    if (-not $item) { return $null }

    if (-not $item.PSIsContainer) {
        if ($item.Extension -match '\.l5k$|\.l5x$') {
            return $item.FullName
        }
        return $null
    }

    $candidate = Get-ChildItem -Path $item.FullName -Include *.l5k, *.l5x -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($candidate) {
        return $candidate.FullName
    }
    return $null
}

function Decode-Html([string]$text) {
    if ([string]::IsNullOrWhiteSpace($text)) { return '' }
    return [System.Net.WebUtility]::HtmlDecode($text)
}

function Parse-L5k {
    param([string]$Path)

    $tasks = @()
    $programs = @()
    $routines = @()

    $taskPattern = [regex]::new('^\s*TASK\s+([\w-]+)\b')
    $progPattern = [regex]::new('^\s*PROGRAM\s+([\w-]+)\b')
    $routPattern = [regex]::new('^\s*ROUTINE\s+([\w-]+)\b')
    $endRoutine = [regex]::new('^\s*END_ROUTINE\b')
    $jsrPattern = [regex]::new('JSR\s*\(\s*([\w-]+)', 'IgnoreCase')

    $currentProgram = $null
    $currentRoutine = $null
    $jsrCount = 0

    foreach ($line in (Get-Content -Path $Path -Encoding UTF8)) {
        $taskMatch = $taskPattern.Match($line)
        if ($taskMatch.Success) {
            $tasks += $taskMatch.Groups[1].Value
            continue
        }

        $progMatch = $progPattern.Match($line)
        if ($progMatch.Success) {
            $currentProgram = $progMatch.Groups[1].Value
            $programs += $currentProgram
            $currentRoutine = $null
            $jsrCount = 0
            continue
        }

        $routMatch = $routPattern.Match($line)
        if ($routMatch.Success) {
            $currentRoutine = $routMatch.Groups[1].Value
            $jsrCount = 0
            continue
        }

        if ($currentRoutine) {
            $jsrCount += $jsrPattern.Matches($line).Count
            if ($endRoutine.IsMatch($line)) {
                $routines += [PSCustomObject]@{
                    Rotina = $currentRoutine
                    Programa = if ($currentProgram) { $currentProgram } else { 'Global' }
                    JSRs = $jsrCount
                }
                $currentRoutine = $null
                $jsrCount = 0
            }
        }
    }

    return @{
        Tasks = $tasks | Select-Object -Unique
        Programs = $programs | Select-Object -Unique
        Routines = $routines
    }
}

function Parse-L5x {
    param([string]$Path)

    $xmlText = Get-Content -Path $Path -Raw -Encoding UTF8
    $tasks = [regex]::Matches($xmlText, '<Task[^>]*Name="([^"]+)"', 'IgnoreCase') | ForEach-Object { $_.Groups[1].Value }
    $programs = [regex]::Matches($xmlText, '<Program[^>]*Name="([^"]+)"', 'IgnoreCase') | ForEach-Object { $_.Groups[1].Value }
    $routines = @()

    $routineMatches = [regex]::Matches($xmlText, '<Routine[^>]*Name="([^"]+)"[^>]*>', 'IgnoreCase')
    foreach ($match in $routineMatches) {
        $routines += [PSCustomObject]@{
            Rotina = $match.Groups[1].Value
            Programa = ''
            JSRs = 0
        }
    }

    # Conta chamadas JSR nas seções Text/Line.
    $textMatches = [regex]::Matches($xmlText, '<Text>([\s\S]*?)</Text>', 'IgnoreCase')
    $stMatches = [regex]::Matches($xmlText, '<Line>([\s\S]*?)</Line>', 'IgnoreCase')
    $allLines = @()
    $allLines += $textMatches | ForEach-Object { Decode-Html $_.Groups[1].Value }
    $allLines += $stMatches | ForEach-Object { Decode-Html $_.Groups[1].Value }
    $jsrCount = ([regex]::Matches(($allLines -join "`n"), 'JSR\s*\(', 'IgnoreCase')).Count

    return @{
        Tasks = $tasks | Select-Object -Unique
        Programs = $programs | Select-Object -Unique
        Routines = $routines
        JSRCount = $jsrCount
    }
}

if (-not $InputPath -and (Test-Path $settingsPath)) {
    try {
        $settings = Get-Content -Path $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($settings.tiaPath) { $InputPath = [string]$settings.tiaPath }
    } catch {}
}

$rockwellFile = Resolve-RockwellFile -BasePath $InputPath
if (-not $rockwellFile) {
    throw 'Arquivo Rockwell (.L5K/.L5X) nao encontrado na origem informada.'
}

$ext = [System.IO.Path]::GetExtension($rockwellFile).ToLowerInvariant()
$report = if ($ext -eq '.l5x') { Parse-L5x -Path $rockwellFile } else { Parse-L5k -Path $rockwellFile }

$tasksCount = ($report.Tasks | Measure-Object).Count
$programsCount = ($report.Programs | Measure-Object).Count
$routinesCount = ($report.Routines | Measure-Object).Count

$htmlHeader = @"
<!DOCTYPE html>
<html lang='pt-BR'>
<head>
  <meta charset='UTF-8'>
  <title>Documentacao Rockwell</title>
  <style>
    body { font-family: Segoe UI, Arial, sans-serif; margin: 20px; background: #f7f9fc; color: #1f2937; }
    h1 { color: #0b4f74; border-bottom: 2px solid #0ea5e9; padding-bottom: 8px; }
    .summary { background: #eef7ff; padding: 12px; border-left: 5px solid #0ea5e9; margin-bottom: 16px; }
    table { width: 100%; border-collapse: collapse; background: #fff; }
    th, td { padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: left; }
    thead { background: #0b4f74; color: #fff; }
    .footer { margin-top: 20px; color: #64748b; font-size: 12px; }
  </style>
</head>
<body>
  <h1>Documentacao Rockwell</h1>
  <div class='summary'>
    <strong>Origem:</strong> $rockwellFile<br>
    <strong>Resumo:</strong> $tasksCount Tasks, $programsCount Programs, $routinesCount Rotinas.
  </div>
"@

$htmlBody = "<h2>Rotinas</h2><table><thead><tr><th>Rotina</th><th>Programa</th><th>JSRs</th></tr></thead><tbody>"
foreach ($routine in $report.Routines) {
    $htmlBody += "<tr><td>$($routine.Rotina)</td><td>$($routine.Programa)</td><td>$($routine.JSRs)</td></tr>"
}
$htmlBody += "</tbody></table>"

$htmlFooter = @"
  <div class='footer'>Relatorio gerado em $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss').</div>
</body>
</html>
"@

$finalHtml = $htmlHeader + $htmlBody + $htmlFooter
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outputPath, $finalHtml, $utf8NoBom)

Write-Host ('Sucesso. HTML gerado em: ' + $outputPath) -ForegroundColor Green
