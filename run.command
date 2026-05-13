#!/usr/bin/env bash
# Cubic Spline Interpolation — one-command runner (macOS / Linux)
# Checks R, installs shiny if needed, then launches the app in your browser.

set -e

APP_FILE="FinalActivity_deJesusLimPumarManaliliSingh.R"

cd "$(dirname "$0")"

# 1. Check R is installed
if ! command -v Rscript >/dev/null 2>&1; then
  echo ""
  echo "R is not installed. Please install R first:"
  echo "  https://cran.r-project.org/bin/macosx/    (macOS)"
  echo "  https://cran.r-project.org/bin/linux/     (Linux)"
  echo ""
  echo "If you have Homebrew on macOS, you can also run:"
  echo "  brew install --cask r"
  echo ""
  if command -v open >/dev/null 2>&1; then
    open "https://cran.r-project.org/bin/macosx/" 2>/dev/null || true
  fi
  exit 1
fi

# 2. Install shiny if needed (idempotent)
echo "Checking shiny package..."
Rscript -e 'if (!requireNamespace("shiny", quietly=TRUE)) install.packages("shiny", repos="https://cloud.r-project.org")'

# 3. Run the app
echo ""
echo "Starting the app — your browser will open shortly."
echo "Press Ctrl+C in this terminal to stop."
echo ""
exec Rscript -e "shiny::runApp('${APP_FILE}', launch.browser=TRUE)"
