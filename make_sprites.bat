@echo off
rem Double-click this file to turn every image in art_inbox into a game sprite.
setlocal
set "ROOT=%~dp0."
set "ASE=%ASEPRITE%"
if not defined ASE if exist "C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe" set "ASE=C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe"
if not defined ASE if exist "C:\Program Files\Steam\steamapps\common\Aseprite\Aseprite.exe" set "ASE=C:\Program Files\Steam\steamapps\common\Aseprite\Aseprite.exe"
if not defined ASE if exist "C:\Program Files\Aseprite\Aseprite.exe" set "ASE=C:\Program Files\Aseprite\Aseprite.exe"
if not defined ASE (
  echo Could not find Aseprite.exe.
  echo Open this file in Notepad and put the full path after  set "ASE=  on line 5.
  pause
  exit /b 1
)
echo Using "%ASE%"
if exist "%ROOT%\art_inbox\last_run.txt" del "%ROOT%\art_inbox\last_run.txt"
"%ASE%" -b --script-param "root=%ROOT%" --script "%ROOT%\tools\sprite_pipeline.lua"
if exist "%ROOT%\art_inbox\last_run.txt" (
  type "%ROOT%\art_inbox\last_run.txt"
) else (
  echo Aseprite ran but wrote no report. Something went wrong before the script started.
)
pause
