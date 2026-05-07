#!/usr/bin/env Rscript
# Runs our R cubic_spline on the same test cases as run_js.js
# Outputs JSON to stdout for verify_r.py to compare against scipy.

# Source ONLY the algorithm functions from app.R (not the Shiny app)
src <- readLines("../app/app.R")
end <- grep("^# === UI:", src)[1] - 1
algo_text <- paste(src[1:end], collapse = "\n")
e <- new.env()
suppressMessages(suppressWarnings(eval(parse(text = algo_text), envir = e)))
cubic_spline <- e$cubic_spline
eval_spline  <- e$eval_spline

E <- exp(1)
cases <- list(
  textbook_natural = list(
    xs = c(0, 1, 2, 3),
    ys = c(1, E, E^2, E^3),
    type = "natural"
  ),
  textbook_clamped = list(
    xs = c(0, 1, 2, 3),
    ys = c(1, E, E^2, E^3),
    type = "clamped",
    fp0 = 1, fpn = E^3
  ),
  sine_natural = list(
    xs = 0:6,
    ys = sin(0:6),
    type = "natural"
  ),
  runge_natural = list(
    xs = c(-1, -0.5, 0, 0.5, 1),
    ys = 1 / (1 + 25 * c(-1, -0.5, 0, 0.5, 1)^2),
    type = "natural"
  ),
  nonuniform = list(
    xs = c(0, 0.3, 1.0, 2.5, 4.0),
    ys = c(0, 0.5, 0.7, -0.2, 1.1),
    type = "natural"
  )
)

out <- list()
M <- 11
for (name in names(cases)) {
  c_ <- cases[[name]]
  fp0 <- if (is.null(c_$fp0)) 0 else c_$fp0
  fpn <- if (is.null(c_$fpn)) 0 else c_$fpn
  sp <- cubic_spline(c_$xs, c_$ys, c_$type, fp0, fpn)
  x0 <- c_$xs[1]; xn <- c_$xs[length(c_$xs)]
  samples <- lapply(0:(M - 1), function(k) {
    x <- x0 + (xn - x0) * (k / (M - 1))
    list(x, eval_spline(sp, x))
  })
  out[[name]] <- list(
    a = sp$a, b = sp$b, c = sp$c, d = sp$d, h = sp$h,
    samples = samples
  )
}

cat(jsonlite::toJSON(out, auto_unbox = TRUE, digits = 17, null = "null"))
