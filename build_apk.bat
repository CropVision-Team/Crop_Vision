@echo off
title CropVision — Android APK Builder
echo ========================================================
echo             CropVision Android APK Builder
echo ========================================================
echo.
echo Choose the APK build type:
echo   [1] Debug APK   (Fastest, recommended for quick testing on any phone)
echo   [2] Release APK (Optimized, production performance)
echo.
set /p choice="Enter 1 or 2 (Default is 1): "

cd /d "%~dp0mobile_app"

if "%choice%"=="2" (
    echo.
    echo Building Release APK...
    flutter build apk --release
) else (
    echo.
    echo Building Debug APK...
    flutter build apk --debug
)

echo.
echo ========================================================
echo  Build Finished!
echo  Your APK file is located at:
echo  mobile_app\build\app\outputs\flutter-apk\
echo ========================================================
echo.
pause
