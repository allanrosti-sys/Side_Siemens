$cscPath='C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$dllPath='C:\Program Files\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll'
$sourcePath='C:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\using Siemens.cs'
Write-Host "csc exists: $(Test-Path $cscPath)"
Write-Host "dll exists: $(Test-Path $dllPath)"
Write-Host "source exists: $(Test-Path $sourcePath)"
& $cscPath /nologo /target:exe /out:C:\temp\foo.exe /reference:$dllPath $sourcePath
Write-Host "exit code: $LASTEXITCODE"