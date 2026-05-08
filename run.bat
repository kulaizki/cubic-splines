@echo off
REM Cubic Spline Interpolation - one-command runner (Windows)
REM Checks R, installs shiny if needed, then launches the app in your browser.

setlocal

set "APP_FILE=FinalActivity_deJesusLimPumarManaliliSingh.R"

cd /d "%~dp0"

REM 1. Check R is installed
where Rscript >nul 2>nul
if errorlevel 1 (
  echo.
  echo R is not installed. Opening the download page...
  echo Please install R, then run this script again.
  echo.
  start "" "https://cran.r-project.org/bin/windows/base/"
  pause
  exit /b 1
)

REM 2. Install shiny if needed
echo Checking shiny package...
Rscript -e "if (!requireNamespace('shiny', quietly=TRUE)) install.packages('shiny', repos='https://cloud.r-project.org')"
if errorlevel 1 (
  echo Failed to install shiny. Check your internet connection.
  pause
  exit /b 1
)

REM 3. Run the app
echo.
echo Starting the app - your browser will open shortly.
echo Close this window or press Ctrl+C to stop.
echo.
Rscript -e "shiny::runApp('%APP_FILE%', launch.browser=TRUE)"
