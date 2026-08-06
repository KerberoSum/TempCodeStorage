@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "%~dp0Launcher_Widget.ps1"
