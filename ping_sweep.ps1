# ping_sweep.ps1 - Escaneo de red por ping
$ErrorActionPreference = "Continue"
$labPath = "C:\Prueba"
$logPath = "$labPath\log.txt"
$resultsPath = "$labPath\ping_results.txt"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - PING_SWEEP - $Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
}

Write-Log "Iniciando ping sweep..."

try {
    # Obtener IP local y calcular rango de red
    $adapter = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*"}
    $localIP = $adapter.IPAddress
    $subnet = $adapter.PrefixLength
    $network = $localIP.Substring(0, $localIP.LastIndexOf('.') + 1) + "0"
    
    Write-Log "Interfaz detectada: $localIP/$subnet"
    Write-Log "Escaneando red: $network*"
    
    # Ping sweep al rango /24 (255 hosts)
    $results = @()
    1..254 | ForEach-Object {
        $ip = "$network$_"
        $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
        if ($ping) {
            $results += $ip
            Write-Host "✓ $ip" -ForegroundColor Green
        }
    }
    
    # Guardar resultados
    $results | Out-File -FilePath $resultsPath -Encoding UTF8
    Write-Log "Ping sweep completado. $($results.Count) hosts activos guardados en $resultsPath"
    
    Write-Host "`n✅ Ping sweep completado. $($results.Count) hosts encontrados." -ForegroundColor Cyan
    Write-Host "Resultados: $resultsPath" -ForegroundColor Yellow
    
} catch {
    Write-Log "Error en ping sweep: $_"
    Write-Error "Error: $_"
}