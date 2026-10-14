@echo off
rem ============================================================
rem  Feed the Scorchpot Easy Mod - re-apply after a game update
rem  Use this ONLY after the game was updated to a new version:
rem  it re-bases the vanilla backup on the current game file and
rem  re-applies the patch.
rem  (Chinese messages are printed by ScorchpotEasy.ps1 itself,
rem   because cmd.exe cannot safely mix code pages in a .bat file)
rem ============================================================
setlocal
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ScorchpotEasy.ps1" -Repatch -RefreshBackup %*
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo [ERROR] Re-patch failed with exit code %RC% - see the message above.
) else (
  echo [DONE] Patch re-applied for the current game version.
)
echo.
pause
endlocal
