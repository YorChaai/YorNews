@echo off
setlocal
cd /d "%~dp0"
title YorNews - Launcher

:menu
cls
echo ============================================
echo            YORNEWS APP LAUNCHER
echo ============================================
echo.
echo   [1] Jalankan Website Release (Browser)
echo   [2] Install ^& Buka di HP (Release APK)
echo   [3] Jalankan Mode Debug di HP (Hot Reload)
echo   [4] Jalankan Mode Debug di Chrome (Hot Reload)
echo   [5] Build Ulang Release (Web ^& APK Android)
echo   [0] Keluar
echo.
set /p choice=Pilih menu [0-5]: 

if "%choice%"=="1" (
    call "%~dp0run_web.bat"
    goto menu
)
if "%choice%"=="2" (
    call "%~dp0run_hp.bat"
    goto menu
)
if "%choice%"=="3" (
    call flutter run
    pause
    goto menu
)
if "%choice%"=="4" (
    call flutter run -d chrome
    pause
    goto menu
)
if "%choice%"=="5" (
    echo [YorNews] Membangun Web Release...
    call flutter build web --release
    if errorlevel 1 (
        echo [ERROR] Gagal build web.
        pause
        goto menu
    )
    echo [YorNews] Membangun APK Android Release...
    call flutter build apk --release
    if errorlevel 1 (
        echo [ERROR] Gagal build APK.
        pause
        goto menu
    )
    echo [SELESAI] Web dan APK Release berhasil dibangun!
    pause
    goto menu
)
if "%choice%"=="0" exit /b 0

goto menu

