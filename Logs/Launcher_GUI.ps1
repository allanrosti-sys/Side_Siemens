# Script: Launcher GUI
# Objetivo: Painel para executar ferramentas sem usar linha de comando.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptPath

function Execute-Item {
    param(
        [string]$ScriptName,
        [bool]$IsScript
    )

    $paths = @(
        (Join-Path $scriptPath $ScriptName),
        (Join-Path $projectRoot $ScriptName)
    )

    $target = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($null -eq $target) {
        [System.Windows.Forms.MessageBox]::Show("Arquivo nao encontrado: $ScriptName", "Erro") | Out-Null
        $script:statusLabel.Text = "Status: erro - arquivo nao encontrado."
        $script:statusLabel.ForeColor = [System.Drawing.Color]::Red
        return
    }

    $script:statusLabel.Text = "Status: executando $ScriptName..."
    $script:statusLabel.ForeColor = [System.Drawing.Color]::Blue
    $script:form.Refresh()

    if ($IsScript) {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$target`""
    }
    else {
        Invoke-Item $target
    }

    $script:statusLabel.Text = "Status: comando iniciado."
    $script:statusLabel.ForeColor = [System.Drawing.Color]::Green
}

$script:form = New-Object System.Windows.Forms.Form
$form.Text = "TIA Portal Tools - Painel de Controle"
$form.Size = New-Object System.Drawing.Size(520, 630)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

$title = New-Object System.Windows.Forms.Label
$title.Text = "TIA Portal Automation Tools"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(0, 70, 105)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(20, 15)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Gerenciador de Projetos e Blocos"
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$subtitle.ForeColor = [System.Drawing.Color]::Gray
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(22, 45)
$form.Controls.Add($subtitle)

$items = @(
    @{ T="1. Exportar Projeto"; Desc="Executa backup/exportacao em XML."; S="RunExporterWithAttach.ps1"; IsScript=$true; Color=[System.Drawing.Color]::AliceBlue },
    @{ T="2. Importar Blocos"; Desc="Importa SCL da pasta NewBlocks para o TIA."; S="Import-New-Blocks.ps1"; IsScript=$true; Color=[System.Drawing.Color]::Honeydew },
    @{ T="3. Ciclo Completo"; Desc="Executa Exportar -> Commit -> Importar."; S="Run-Full-Cycle.ps1"; IsScript=$true; Color=[System.Drawing.Color]::LavenderBlush },
    @{ T="4. Gerar Documentacao"; Desc="Gera documentacao HTML do projeto."; S="Generate-Documentation.ps1"; IsScript=$true; Color=[System.Drawing.Color]::MistyRose },
    @{ T="5. Push para GitHub"; Desc="Envia alteracoes para o repositorio remoto."; S="Push-To-GitHub.ps1"; IsScript=$true; Color=[System.Drawing.Color]::LightCyan },
    @{ T="6. Ajuda / Estudos"; Desc="Abre o guia de estudos do projeto."; S="ESTUDOS_INICIAIS.md"; IsScript=$false; Color=[System.Drawing.Color]::White }
)

$y = 80
foreach ($item in $items) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $item.T
    $button.Tag = $item.S
    $button.Name = $item.IsScript.ToString()
    $button.Location = New-Object System.Drawing.Point(30, ($y + 5))
    $button.Size = New-Object System.Drawing.Size(450, 40)
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $button.BackColor = $item.Color
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 1
    $button.FlatAppearance.BorderColor = [System.Drawing.Color]::LightGray
    $button.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $button.Padding = New-Object System.Windows.Forms.Padding(10, 0, 0, 0)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Add_Click({ Execute-Item $this.Tag ([bool]::Parse($this.Name)) })
    $form.Controls.Add($button)

    $desc = New-Object System.Windows.Forms.Label
    $desc.Text = $item.Desc
    $desc.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
    $desc.ForeColor = [System.Drawing.Color]::DimGray
    $desc.Location = New-Object System.Drawing.Point(35, ($y + 48))
    $desc.AutoSize = $true
    $form.Controls.Add($desc)

    $y += 70
}

$separator = New-Object System.Windows.Forms.Label
$separator.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$separator.Location = New-Object System.Drawing.Point(20, ($y + 10))
$separator.Size = New-Object System.Drawing.Size(470, 2)
$form.Controls.Add($separator)

$btnLog = New-Object System.Windows.Forms.Button
$btnLog.Text = "Abrir Pasta de Logs"
$btnLog.Location = New-Object System.Drawing.Point(30, ($y + 25))
$btnLog.Size = New-Object System.Drawing.Size(450, 30)
$btnLog.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$btnLog.BackColor = [System.Drawing.Color]::White
$btnLog.Add_Click({ Invoke-Item $scriptPath })
$form.Controls.Add($btnLog)

$script:statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Status: pronto."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$statusLabel.Location = New-Object System.Drawing.Point(30, ($y + 65))
$statusLabel.AutoSize = $true
$form.Controls.Add($statusLabel)

$form.ShowDialog() | Out-Null
