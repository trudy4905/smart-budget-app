@echo off
chcp 65001 > nul
cd /d "%~dp0"
echo ===================================================
echo   Smart Budget App - Android Emulator Launcher
echo ===================================================

echo [1/2] Android Emulator 확인 중...
where adb >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    set "PATH=%LOCALAPPDATA%\Android\Sdk\platform-tools;%PATH%"
)

adb devices | findstr /i "device" | findstr /i "emulator" >nul
if %ERRORLEVEL% NEQ 0 (
    echo 에뮬레이터가 실행되어 있지 않아 구동합니다...
    if exist "%LOCALAPPDATA%\AndroidCLI\android.exe" (
        start "" "%LOCALAPPDATA%\AndroidCLI\android.exe" emulator start medium_phone
    ) else if exist "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" (
        start "" "%LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe" -avd medium_phone
    )
    echo 에뮬레이터 부팅 대기 중...
    adb wait-for-device
) else (
    echo 에뮬레이터가 이미 실행 중입니다.
)

echo.
echo [2/2] Flutter 앱 실행 (flutter run)...
cd /d "%~dp0flutter_app"
call C:\src\flutter\bin\flutter.bat run

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo 실행 중 오류가 발생했습니다. (Exit Code: %ERRORLEVEL%)
    pause
)
