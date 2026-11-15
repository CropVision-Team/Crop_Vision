# CropVision Full Project Launcher
Write-Host "========================================================" -ForegroundColor Green
Write-Host "          CropVision — Full Project Launcher            " -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Start Model Inference Server (Port 8000)
Write-Host "`n[1/3] Starting Model Inference Server on port 8000..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$rootDir\model'; python inference_server.py"

# 2. Start Website Server (Port 3000)
Write-Host "[2/3] Starting Website Server on port 3000..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$rootDir\website'; python -m http.server 3000"

# 3. Wait and Open Browser
Start-Sleep -Seconds 3
Write-Host "[3/3] Opening Website in default browser..." -ForegroundColor Cyan
Start-Process "http://localhost:3000"

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " All Services Running!" -ForegroundColor Green
Write-Host " • Website:          http://localhost:3000" -ForegroundColor White
Write-Host " • Model Inference:  http://localhost:8000" -ForegroundColor White
Write-Host "`n To launch the Flutter Mobile App:" -ForegroundColor Yellow
Write-Host "   cd mobile_app" -ForegroundColor Yellow
Write-Host "   flutter run -d chrome" -ForegroundColor Yellow
Write-Host "========================================================`n" -ForegroundColor Green
