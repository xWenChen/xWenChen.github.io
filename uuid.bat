@echo off
setlocal enabledelayedexpansion

rem "生成 uuid 的脚本"

for /f "tokens=* USEBACKQ" %%F in (`powershell -command "[guid]::NewGuid().ToString().ToUpper()"`) do (
  set "guid=%%F"
)

set "guid=%guid:-=%"
echo.
echo %guid%
echo.