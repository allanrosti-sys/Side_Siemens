@echo off
REM Monitor AI_SYNC.md para mensagens de outras IAs
REM Script simples que verifica periodicamente por atualizações

setlocal enabledelayedexpansion
set "syncFile=c:\Users\Administrador\Documents\tirol-ipiranga-os18869_20260224_PE_V20\Logs\AI_SYNC.md"
set "lastSize=0"

echo.
echo === Monitor AI_SYNC.md Iniciado ===
echo Monitorando: %syncFile%
echo Procurando: Mensagens para Copilot, Você
echo Pressione Ctrl+C para parar
echo.

:loop
if exist "%syncFile%" (
    for %%A in ("%syncFile%") do set "currentSize=%%~zA"
    
    if not "!currentSize!"=="!lastSize!" (
        cls
        echo [%DATE% %TIME%] ^[ATUALIZADO^] Arquivo foi modificado
        echo.
        echo === CONTEUDO RECENTE DO AI_SYNC.md ===
        type "%syncFile%"
        echo.
        echo === FIM DO CONTEUDO ===
        echo.
        echo Procurando mensagens para COPILOT...
        findstr /I "copilot voce você" "%syncFile%"
        echo.
        set "lastSize=!currentSize!"
    ) else (
        title Monitor AI_SYNC.md - Aguardando atualizacoes...
    )
)

timeout /t 5 /nobreak
goto loop
