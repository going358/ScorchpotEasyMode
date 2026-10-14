@echo off
rem ============================================================
rem  Feed the Scorchpot Easy Mod - installer
rem  (Chinese messages are printed by ScorchpotEasy.ps1 itself,
rem   because cmd.exe cannot safely mix code pages in a .bat file)
rem ============================================================
setlocal
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ScorchpotEasy.ps1" -Install %*
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo [ERROR] Install failed with exit code %RC% - see the message above.
  echo [ERROR] Send the message above back to the mod author.
) else (
  echo [DONE] Installed. In game, press F9 to open the mod panel.
)
echo.
pause
endlocal
