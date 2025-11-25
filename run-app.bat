@echo off
REM Run Cognitive Castle AIR Application
setlocal enabledelayedexpansion

set AIR_SDK=C:\AIR\SDK\AIRSDK_51.2.2
set PROJECT_DIR=%~dp0
set APP_XML=%PROJECT_DIR%CognitiveCastle-app.xml

echo Starting Cognitive Castle...
echo Project: %PROJECT_DIR%
echo SDK: %AIR_SDK%

"%AIR_SDK%\bin\adl.exe" "%APP_XML%" "%PROJECT_DIR%bin"

pause
