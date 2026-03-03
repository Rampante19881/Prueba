# setup_lab.ps1 - LABORATORIO COMPLETO AUTOMÁTICO
$ErrorActionPreference = "Continue"
$labPath = "C:\Prueba"
$logPath = "$labPath\log.txt"
$githubRawBase = "https://raw.githubusercontent.com/Rampante19881/Prueba/main/"

# Función para escribir logs
function Write-Log {
    param([string]$Message, [string]$Phase = "")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $phaseTag = if ($Phase) { "[$Phase] " } else { "" }
    "$timestamp - $phaseTag$Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
    Write-Host "$timestamp - $phaseTag$Message" -ForegroundColor Green
}

# Función para ejecutar script con timeout
function Invoke-ScriptWithTimeout {
    param([string]$ScriptPath, [string]$Phase)
    try {
        Write-Log "Ejecutando $Phase : $ScriptPath" $Phase
        $job = Start-Job -ScriptBlock { & $using:ScriptPath }
        $timeout = 120  # 2 minutos max
        if (Wait-Job $job -Timeout $timeout) {
            $result = Receive-Job $job
            Write-Log "✓ $Phase completado exitosamente" $Phase
            Remove-Job $job
            return $true
        } else {
            Stop-Job $job
            Remove-Job $job -Force
            Write-Log "✗ $Phase TIMEOUT ($timeout s)" $Phase
            return $false
        }
    }
    catch {
        Write-Log "✗ $Phase ERROR: $_" $Phase
        return $false
    }
}

Write-Host " INICIANDO LABORATORIO COMPLETO AUTOMÁTICO..." -ForegroundColor Cyan
Write-Log "=== LABORATORIO AUTOMÁTICO INICIADO ==="

# 1. Crear carpeta principal
if (!(Test-Path $labPath)) {
    New-Item -ItemType Directory -Path $labPath -Force | Out-Null
    Write-Log "Carpeta laboratorio creada: $labPath"
}

# 2. Descargar scripts
$scripts = @{
    "ping_sweep.ps1" = "$githubRawBase ping_sweep.ps1"
    "copy.ps1" = "$githubRawBase copy.ps1"
    "estenxiones.ps1" = "$githubRawBase estenxiones.ps1"
}

Write-Log "=== FASE 1: DESCARGA DE SCRIPTS ==="
foreach ($scriptName in $scripts.Keys) {
    $scriptPath = "$labPath\$scriptName"
    $url = $scripts[$scriptName]
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $scriptPath -UseBasicParsing -ErrorAction Stop
        Write-Log "✓ $scriptName descargado"
    }
    catch {
        Write-Log "✗ Error descargando $scriptName`: $_"
    }
}

# 3. EJECUTAR SECUENCIA AUTOMÁTICA
Write-Log "=== FASE 2: EJECUCIÓN AUTOMÁTICA ==="

$success = @()

# Ejecutar ping_sweep
$success += Invoke-ScriptWithTimeout "$labPath\ping_sweep.ps1" "PING_SWEEP"

# Esperar 2 segundos
Start-Sleep 2

# Ejecutar copy
$success += Invoke-ScriptWithTimeout "$labPath\copy.ps1" "COPY"

# Esperar 2 segundos
Start-Sleep 2

# Ejecutar extensions
$success += Invoke-ScriptWithTimeout "$labPath\estenxiones.ps1" "EXTENSIONS"

# 4. RESUMEN FINAL
Write-Log "=== RESUMEN FINAL ==="
$totalTests = 3
$passedTests = ($success | Where-Object {$_}).Count
Write-Log "Pruebas completadas: $passedTests/$totalTests"

if ($passedTests -eq $totalTests) {
    Write-Log " LABORATORIO COMPLETADO 100% EXITOSO"
    Write-Host "`n  TODO COMPLETADO CORRECTAMENTE" -ForegroundColor Green -BackgroundColor Black
} elseif ($passedTests -gt 0) {
    Write-Log " LABORATORIO PARCIALMENTE COMPLETADO ($passedTests/$totalTests)"
    Write-Host "`n  COMPLETADO PARCIALMENTE ($passedTests/$totalTests)" -ForegroundColor Yellow
} else {
    Write-Log " LABORATORIO FALLÓ COMPLETAMENTE"
    Write-Host "`n FALLÓ TODO EL PROCESO" -ForegroundColor Red
}

Write-Host "`n Resultados en: $labPath" -ForegroundColor Cyan
Write-Host " Log completo: $logPath" -ForegroundColor Cyan
Write-Host "`n Proceso finalizado: $(Get-Date)" -ForegroundColor Magenta

# Pausa final para ver resultados
Read-Host "Presiona ENTER para cerrar"