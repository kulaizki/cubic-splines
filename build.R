#!/usr/bin/env Rscript
# Build script: shinylive export + dark-background patch on dist/index.html
# Run: Rscript build.R

shinylive::export("app", "dist", quiet = TRUE)

idx_path <- "dist/index.html"
html <- readLines(idx_path, warn = FALSE)

# Copy favicon to dist so the OUTER shinylive shell can reference it
file.copy("favicon.svg", "dist/favicon.svg", overwrite = TRUE)

# Update outer shell <title> (default is "Shiny App")
html <- sub(
  "<title>Shiny App</title>",
  "<title>Cubic Spline Interpolation</title>",
  html, fixed = TRUE
)

# Inject favicon + dark theme on the OUTER shinylive shell (html, body, #root, scrollbar)
# so there are no white gaps when scrolling past the iframe.
inject <- paste0(
  "<link rel='icon' type='image/svg+xml' href='./favicon.svg'>",
  "<meta name='color-scheme' content='dark'>",
  "<style>",
  ":root{color-scheme:dark;}",
  "html,body{background:#09090b !important;margin:0;color:#fafafa;",
  "  color-scheme:dark;",
  "  font-family:Manrope,system-ui,-apple-system,Segoe UI,Roboto,sans-serif;}",
  "#root{background:#09090b !important;}",
  "::-webkit-scrollbar{width:8px;height:8px;}",
  "::-webkit-scrollbar-track{background:#09090b !important;}",
  "::-webkit-scrollbar-corner{background:#09090b !important;}",
  "::-webkit-scrollbar-thumb{background:#3f3f46;border-radius:4px;border:2px solid #09090b;}",
  "::-webkit-scrollbar-thumb:hover{background:#71717a;}",
  "html{scrollbar-color:#3f3f46 #09090b;scrollbar-width:thin;}",
  "</style>"
)

# place the style right before </head>
html <- sub("</head>", paste0(inject, "</head>"), html, fixed = TRUE)
writeLines(html, idx_path)
cat("dist/ built and patched.\n")
