# estenxiones.ps1 - Cambio de extensiones a .prueba
$ErrorActionPreference = "Continue"
$labPath = "C:\Prueba"
$logPath = "$labPath\log.txt"
$stagedPath = "$labPath\staged_files"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - EXTENSIONS - $Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
}

Write-Log "Iniciando cambio de extensiones..."

try {
    if (!(Test-Path $stagedPath)) {
        Write-Log " Carpeta staged no encontrada: $stagedPath"
        Write-Error "Ejecuta copy.ps1 primero"
        exit 1
    }

    $changed = 0
    Get-ChildItem -Path $stagedPath -File | ForEach-Object {
        $newName = $_.Name -replace '\.[^.]*$', '.prueba'
        $newPath = Join-Path $_.DirectoryName $newName
        
        if ($newName -ne $_.Name) {
            Rename-Item -Path $_.FullName -NewName $newName -Force
            Write-Log "Renombrado: $($_.Name) -> $newName"
            $changed++
            Write-Host "✓ $($_.Name) -> $newName" -ForegroundColor Green
        }
    }

    Write-Log "Cambio de extensiones completado: $changed archivos procesados"
    Write-Host "`n $($changed) archivos renombrados a .prueba" -ForegroundColor Cyan
    Write-Host "Carpeta: $stagedPath" -ForegroundColor Yellow

} catch {
    Write-Log "Error cambiando extensiones: $_"
    Write-Error "Error: $_"
}