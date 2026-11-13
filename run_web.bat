@echo off
setlocal
cd /d "%~dp0"
title YorNews - Web Release

if not exist "build\web\index.html" (
    echo [YorNews] Build web release belum ada, sedang compile...
    call flutter build web --release
    if errorlevel 1 (
        echo [ERROR] Gagal build web release.
        pause
        exit /b 1
    )
)

where python >nul 2>nul
if %errorlevel%==0 (
    echo [YorNews] Menjalankan Web Release di http://localhost:8080
    echo [YorNews] Tekan Ctrl+C atau tutup jendela ini untuk menghentikan server.
    start "" cmd /c "timeout /t 1 /nobreak >nul & start http://localhost:8080"
    python -m http.server 8080 --directory "%~dp0build\web"
) else (
    echo [YorNews] Python tidak ditemukan, menjalankan via Flutter Chrome Release...
    call flutter run -d chrome --release
)

pause

