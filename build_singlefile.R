#!/usr/bin/env Rscript
# Build a single-file R Shiny app for submission/sharing.
# Inlines style.css + app-client.js as raw strings, swaps Chart.js and
# MathJax to CDN URLs (too big to inline), drops favicon. Output is a
# self-contained .R file the user/professor can run with just `library(shiny)`.

css <- paste(readLines("style.css", warn = FALSE), collapse = "\n")
js  <- paste(readLines("app/www/app-client.js", warn = FALSE), collapse = "\n")
app <- readLines("app/app.R", warn = FALSE)

# Trim the imports section: keep only library(shiny).
app <- gsub("^library\\(htmltools\\)\\s*$", "", app)
app <- gsub("^library\\(jsonlite\\)\\s*$",  "", app)

# Surgical substitutions inside the UI block to swap local asset refs.
sub_one <- function(lines, pattern, replacement) {
  hit <- grep(pattern, lines, fixed = TRUE)
  if (length(hit) == 0) stop("Pattern not found: ", pattern)
  for (i in hit) lines[i] <- gsub(pattern, replacement, lines[i], fixed = TRUE)
  lines
}

# Drop favicon link (single-file submission doesn't ship the SVG)
app <- app[!grepl('rel = "icon", type = "image/svg+xml", href = "favicon.svg"', app, fixed = TRUE)]

# style.css link → inline tag (placed via APP_CSS variable)
app <- sub_one(app,
  'tags$link(rel = "stylesheet", href = "style.css"),',
  'tags$style(HTML(APP_CSS)),'
)

# Chart.js local → CDN
app <- sub_one(app,
  'tags$script(src = "chart.umd.min.js")',
  'tags$script(src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js")'
)

# MathJax local → CDN (uses backticks-escaped `async`)
app <- sub_one(app,
  'tags$script(`async` = NA, src = "mathjax/tex-mml-chtml.js"),',
  'tags$script(`async` = NA, src = "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"),'
)

# Body's app-client.js script → inline (placed via APP_CLIENT_JS variable)
app <- sub_one(app,
  'tags$script(src = "app-client.js")',
  'tags$script(HTML(APP_CLIENT_JS))'
)

# Assemble final file: header, asset strings, transformed app.R contents.
header <- c(
  "# ==============================================================",
  "# Cubic Spline Interpolation — single-file R Shiny app",
  "# Run:  Rscript -e 'shiny::runApp(\"FinalActivity_deJesusLimPumarManaliliSingh.R\", launch.browser = TRUE)'",
  "# Or open in RStudio and click Run App.",
  "# Requires: install.packages('shiny')",
  "# Loads Chart.js and MathJax from CDN (needs internet on first run).",
  "# ==============================================================",
  ""
)

# Use a 6-dash raw-string delimiter that doesn't appear in the source.
delim <- "------"
css_block <- c(
  paste0("APP_CSS <- r\"", delim, "("),
  css,
  paste0(")", delim, "\"")
)
js_block <- c(
  paste0("APP_CLIENT_JS <- r\"", delim, "("),
  js,
  paste0(")", delim, "\"")
)

# Place the asset strings AFTER library(shiny) but BEFORE algorithm code.
lib_idx <- grep("^library\\(shiny\\)", app)[1]
out <- c(
  header,
  app[seq_len(lib_idx)],
  "",
  css_block,
  "",
  js_block,
  "",
  app[(lib_idx + 1):length(app)]
)

# Drop any empty leading lines from the inserted blocks but keep readability.
writeLines(out, "FinalActivity_deJesusLimPumarManaliliSingh.R")
cat(sprintf("Built FinalActivity_deJesusLimPumarManaliliSingh.R (%.0f KB, %d lines)\n",
            file.info("FinalActivity_deJesusLimPumarManaliliSingh.R")$size / 1024,
            length(out)))
