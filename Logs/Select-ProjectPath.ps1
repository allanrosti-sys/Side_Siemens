# Script para abrir um seletor de pastas e salvar o resultado no arquivo de configuracao.
# Requer o modo STA para interagir com a GUI do Windows.

param(
    [int]$Port = 8099
)

function Show-FolderBrowserDialog {
    # Garante que o script esta rodando em um processo com o ApartmentState correto.
    if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
        # Se nao estiver em STA, relanca o proprio script em um novo processo forcando STA.
        $command = "& `"$($MyInvocation.MyCommand.Path)`" -Port $Port"
        powershell -NoProfile -STA -Command $command
        return
    }

    try {
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Selecione a pasta raiz do projeto (Ex: a que contem o .ap20 ou .L5X)"
        $dialog.ShowNewFolderButton = $true

        # Tenta abrir o dialogo na ultima pasta usada para conveniencia.
        $settingsFile = Join-Path $PSScriptRoot "web_settings.json"
        if (Test-Path $settingsFile) {
            try {
                $settings = Get-Content -Path $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($settings.tiaPath -and (Test-Path $settings.tiaPath)) {
                    $dialog.SelectedPath = $settings.tiaPath
                }
            }
            catch {}
        }
        
        # Mostra o dialogo e so procede se o usuario clicar 'OK'.
        $result = $dialog.ShowDialog()
        if ($result -eq 'OK') {
            # O vendor atual e lido para ser enviado junto com o caminho.
            $currentVendor = "auto"
            if (Test-Path $settingsFile) {
                try {
                    $settings = Get-Content $settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($settings.vendor) { $currentVendor = $settings.vendor }
                }
                catch {}
            }
            
            # Monta o corpo da requisicao e envia para a API do WebServer.
            $body = @{
                path = $dialog.SelectedPath
                vendor = $currentVendor
            } | ConvertTo-Json
            
            try {
                $url = "http://localhost:$Port/api/project-path"
                Invoke-WebRequest -Uri $url -Method Post -ContentType "application/json" -Body $body -UseBasicParsing | Out-Null
            }
            catch {
                # A falha pode acontecer se o servidor for fechado enquanto o dialogo esta aberto.
                Write-Warning "Nao foi possivel comunicar o novo caminho ao servidor: $($_.Exception.Message)"
            }
        }
    }
    catch {
        # Erros sao silenciados para nao mostrar popups de erro caso o usuario cancele.
    }
    finally {
        if ($dialog) {
            $dialog.Dispose()
        }
    }
}

Show-FolderBrowserDialog
Exit
