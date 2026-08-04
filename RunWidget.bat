@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -File "%~dp0Widget.ps1"
