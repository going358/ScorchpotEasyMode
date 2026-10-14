@echo off
rem ============================================================
rem  Feed the Scorchpot Easy Mod - restore vanilla data.win
rem  Restores the vanilla data.win backup and removes the Mod config.
rem  (Chinese messages are printed by ScorchpotEasy.ps1 itself,
rem   because cmd.exe cannot safely mix code pages in a .bat file)
rem ============================================================
setlocal
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ScorchpotEasy.ps1" -Restore %*
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo [ERROR] Restore failed with exit code %RC% - see the message above.
) else (
  echo [DONE] Vanilla data.win restored.
)
echo.
pause
endlocal
