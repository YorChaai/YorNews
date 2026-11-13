@echo off
setlocal
cd /d "%~dp0"
title YorNews - HP Android Release

if not exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo [YorNews] APK release belum ada, sedang build...
    call flutter build apk --release
    if errorlevel 1 (
        echo [ERROR] Gagal build APK release.
        pause
        exit /b 1
    )
)

echo [YorNews] Mengecek perangkat Android yang terhubung...
adb devices
echo.
echo [YorNews] Memasang APK Release ke HP...
adb install -r "%~dp0build\app\outputs\flutter-apk\app-release.apk"
if errorlevel 1 (
    echo.
    echo [ERROR] Gagal install ke HP. Pastikan kabel USB terhubung,
    echo         USB Debugging aktif, dan "Instal via USB" diizinkan di HP.
    pause
    exit /b 1
)

echo [YorNews] Membuka aplikasi YorNews di HP...
adb shell am start -n com.example.yor_news_app/.MainActivity
echo [SELESAI] Aplikasi YorNews Release sudah berjalan di HP!
pause

