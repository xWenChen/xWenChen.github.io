@echo off
setlocal enabledelayedexpansion

for /f "tokens=* USEBACKQ" %%F in (`powershell -command "[guid]::NewGuid().ToString().ToUpper()"`) do (
  set "guid=%%F"
)

set "guid=%guid:-=%"
echo.
echo %guid%
echo.