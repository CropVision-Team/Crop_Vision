@echo off
title CropVision - Full Project Launcher
echo ========================================================
echo          CropVision - Full Project Launcher
echo ========================================================
echo.
echo [1/3] Starting Model Inference Server on Port 8000...
start "CropVision ML Server" cmd /k "cd /d "%~dp0model" && venv\Scripts\python.exe inference_server.py"

timeout /t 2 >nul

echo [2/3] Starting Documentation Website on Port 3000...
start "CropVision Website" cmd /k "cd /d "%~dp0website" && python -m http.server 3000"

echo [3/3] Opening browser windows...
timeout /t 3 >nul
start http://localhost:3000

echo.
echo ========================================================
echo  All Services Running!
echo  - Website:         http://localhost:3000
echo  - Model Inference: http://localhost:8000
echo.
echo  To install on your Android phone (USB cable required):
echo    1. Open a NEW PowerShell window
echo    2. Run: adb reverse tcp:8000 tcp:8000
echo    3. Then install the APK:
echo       adb install -r mobile_app\build\app\outputs\flutter-apk\app-debug.apk
echo ========================================================
echo.
pause
