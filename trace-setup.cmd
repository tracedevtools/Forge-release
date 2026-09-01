@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/tracedevtools/Forge-release/main/install.ps1 | iex"
echo.
pause
