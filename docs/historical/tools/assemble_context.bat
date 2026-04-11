@echo off
echo Assembling context...
powershell -ExecutionPolicy Bypass -NoExit -File "%~dp0assemble_context.ps1"
pause