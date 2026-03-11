# Script para abrir um seletor de pastas para a acao de importacao.
# Requer o modo STA para interagir com a GUI do Windows.

function Show-FolderBrowserDialog {
    if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
        $command = "& `"$($MyInvocation.MyCommand.Path)`""
        powershell -NoProfile -STA -Command $command
        return
    }

    try {
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Selecione a pasta contendo os arquivos a serem importados (.scl, .udt)"
        $dialog.ShowNewFolderButton = $false

        $result = $dialog.ShowDialog()

        if ($result -eq 'OK') {
            # Para o fluxo de importacao, usamos um arquivo temporario dedicado.
            $tmpFile = Join-Path $PSScriptRoot "import_path.tmp"
            Set-Content -Path $tmpFile -Value $dialog.SelectedPath -Encoding UTF8 -Force
        }
    }
    catch {}
    finally {
        if ($dialog) {
            $dialog.Dispose()
        }
    }
}

Show-FolderBrowserDialog
Exit
