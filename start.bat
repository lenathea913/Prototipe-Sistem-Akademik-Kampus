@echo off
setlocal EnableExtensions
cd /d "%~dp0"
set "rc=0"

echo ============================================
echo    KampusKu - Menjalankan Aplikasi
echo ============================================
echo.

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter tidak ditemukan di PATH.
  echo         Install Flutter lalu tutup dan buka lagi terminal ini.
  echo         https://docs.flutter.dev/get-started/install/windows
  set "rc=1"
  goto :gagal
)

echo [1/2] Mengambil dependensi ^(flutter pub get^)...
call flutter pub get
if errorlevel 1 (
  echo [ERROR] flutter pub get gagal. Periksa koneksi internet Anda.
  set "rc=1"
  goto :gagal
)
echo.

set "dev="
if not "%~1"=="" (
  set "dev=%~1"
  goto :run
)

echo [2/2] Pilih perangkat:
echo    1. Windows desktop
echo    2. Chrome
echo    3. Edge
echo    4. Otomatis ^(emulator Android / perangkat terdeteksi^)
echo.
set "pilihan=4"
set /p pilihan="Pilihan [4]: "

if "%pilihan%"=="1" set "dev=windows"
if "%pilihan%"=="2" set "dev=chrome"
if "%pilihan%"=="3" set "dev=edge"
if "%pilihan%"=="4" set "dev="
if not "%pilihan%"=="1" if not "%pilihan%"=="2" if not "%pilihan%"=="3" if not "%pilihan%"=="4" (
  echo [ERROR] Pilihan tidak dikenal: %pilihan%
  set "rc=1"
  goto :gagal
)

:run
if "%dev%"=="" (
  echo [2/2] Menjalankan aplikasi pada perangkat yang terdeteksi...
  call flutter run
) else (
  echo [2/2] Menjalankan aplikasi pada: %dev%
  call flutter run -d %dev%
)
set "rc=%errorlevel%"

:selesai
echo.
if not "%rc%"=="0" goto :gagal
echo Aplikasi selesai dijalankan.
pause
endlocal
exit /b 0

:gagal
echo.
echo [ERROR] Aplikasi gagal dijalankan ^(kode %rc%^).
pause
endlocal
exit /b %rc%
