@echo off
REM DPI Engine demo - double-click to run. No arguments needed.
cd /d "%~dp0"
set EXE=
if exist build\Release\dpi_engine.exe set EXE=build\Release\dpi_engine.exe
if exist build\dpi_engine.exe set EXE=build\dpi_engine.exe
if exist dpi_engine.exe set EXE=dpi_engine.exe
if "%EXE%"=="" (
    echo dpi_engine.exe not found. Build first: cmake -B build ^& cmake --build build --config Release
    pause
    exit /b 1
)
%EXE% samples\test_dpi.pcap out.pcap --block-app YouTube --block-ip 192.168.1.50
echo.
echo Output wrote to out.pcap - open it in Wireshark to inspect the filtered capture.
pause
