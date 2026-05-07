library(shiny)
library(htmltools)
library(jsonlite)

# === Cubic spline algorithm (Burden & Faires §3.5) ===
cubic_spline <- function(xs, ys, type = "natural", fp0 = 0, fpn = 0) {
  n_pts <- length(xs)
  n <- n_pts - 1
  if (n < 2) stop("Cubic spline needs at least 3 points.")

  h <- diff(xs)
  alpha <- numeric(n + 1)

  if (type == "clamped") {
    alpha[1]     <- 3 * (ys[2] - ys[1]) / h[1] - 3 * fp0
    alpha[n + 1] <- 3 * fpn - 3 * (ys[n + 1] - ys[n]) / h[n]
  }
  if (n >= 2) {
    for (i in 2:n) {
      alpha[i] <- 3 * (ys[i + 1] - ys[i]) / h[i] -
                  3 * (ys[i] - ys[i - 1]) / h[i - 1]
    }
  }

  l <- numeric(n + 1); mu <- numeric(n + 1); z <- numeric(n + 1)
  if (type == "natural") {
    l[1] <- 1; mu[1] <- 0; z[1] <- 0
  } else {
    l[1] <- 2 * h[1]; mu[1] <- 0.5; z[1] <- alpha[1] / l[1]
  }
  if (n >= 2) {
    for (i in 2:n) {
      l[i] <- 2 * (xs[i + 1] - xs[i - 1]) - h[i - 1] * mu[i - 1]
      mu[i] <- h[i] / l[i]
      z[i] <- (alpha[i] - h[i - 1] * z[i - 1]) / l[i]
    }
  }

  c_full <- numeric(n + 1); b <- numeric(n); d <- numeric(n)
  a <- ys[1:n]
  if (type == "natural") {
    l[n + 1] <- 1; z[n + 1] <- 0; c_full[n + 1] <- 0
  } else {
    l[n + 1] <- h[n] * (2 - mu[n])
    z[n + 1] <- (alpha[n + 1] - h[n] * z[n]) / l[n + 1]
    c_full[n + 1] <- z[n + 1]
  }
  for (j in n:1) {
    c_full[j] <- z[j] - mu[j] * c_full[j + 1]
    b[j] <- (ys[j + 1] - ys[j]) / h[j] - h[j] * (c_full[j + 1] + 2 * c_full[j]) / 3
    d[j] <- (c_full[j + 1] - c_full[j]) / (3 * h[j])
  }

  list(
    type = type, xs = xs, ys = ys,
    a = a, b = b, c = c_full[1:n], d = d, h = h,
    trace = list(alpha = alpha, l = l, mu = mu, z = z, c_full = c_full)
  )
}

eval_spline <- function(spline, x) {
  xs <- spline$xs; n <- length(spline$a)
  if (x < xs[1] || x > xs[n + 1]) return(NA_real_)
  i <- 1
  while (i < n && x > xs[i + 1]) i <- i + 1
  dx <- x - xs[i]
  spline$a[i] + spline$b[i] * dx + spline$c[i] * dx^2 + spline$d[i] * dx^3
}

fmt <- function(v, p = 6) {
  if (!is.finite(v)) return(as.character(v))
  if (v == 0) return("0")
  av <- abs(v)
  if (av < 1e-4 || av >= 1e6) return(formatC(v, format = "e", digits = 4))
  formatC(round(v, p), format = "g", digits = p)
}
sgn <- function(v) if (v >= 0) "+" else "-"

# === UI: same DOM as index.html, with Shiny placeholders ===
intro_panel <- tags$section(
  id = "intro", class = "panel is-active", role = "tabpanel",
  div(class = "card",
    tags$span(class = "eyebrow", "Method"),
    tags$h2("What is a Cubic Spline?"),
    tags$p(class = "lead", HTML(
      "A <strong>cubic spline</strong> is a piecewise cubic polynomial that passes through a given set of data points and is <em>smooth</em> at every interior point — value, slope, and curvature all match across adjacent pieces."
    )),
    tags$p(HTML(
      "It avoids the wild oscillations of high-degree polynomial interpolation (<em>Runge's phenomenon</em>), making it the standard tool for smooth interpolation in graphics, engineering, and data science."
    )),
    tags$h3("Definition"),
    tags$p(HTML("Given $n+1$ data points $(x_0, y_0), (x_1, y_1), \\dots, (x_n, y_n)$, a cubic spline $S(x)$ consists of $n$ cubic polynomials, one per interval $[x_i, x_{i+1}]$:")),
    div(class = "math-block", HTML("$$S_i(x) = a_i + b_i(x - x_i) + c_i(x - x_i)^2 + d_i(x - x_i)^3$$")),
    tags$h3("Conditions"),
    tags$ul(class = "conditions",
      tags$li(HTML("<strong>Interpolation:</strong> $S_i(x_i) = y_i$ and $S_i(x_{i+1}) = y_{i+1}$")),
      tags$li(HTML("<strong>Slope continuity:</strong> $S'_{i-1}(x_i) = S'_i(x_i)$")),
      tags$li(HTML("<strong>Curvature continuity:</strong> $S''_{i-1}(x_i) = S''_i(x_i)$")),
      tags$li(HTML("<strong>Boundary conditions</strong> (two more equations needed):"),
        tags$ul(
          tags$li(HTML("<em>Natural:</em> $S''(x_0) = S''(x_n) = 0$")),
          tags$li(HTML("<em>Clamped:</em> $S'(x_0) = f'_0$, $S'(x_n) = f'_n$ (user-supplied slopes)"))
        )
      )
    ),
    tags$h3(HTML("Algorithm (Burden &amp; Faires)")),
    tags$ol(class = "algo",
      tags$li(HTML("Compute interval widths $h_i = x_{i+1} - x_i$.")),
      tags$li(HTML("Set $a_i = y_i$.")),
      tags$li(HTML("Build the tridiagonal system for second-derivative coefficients $c_i$: $$h_{i-1}c_{i-1} + 2(h_{i-1}+h_i)c_i + h_i c_{i+1} = 3\\!\\left(\\tfrac{y_{i+1}-y_i}{h_i} - \\tfrac{y_i - y_{i-1}}{h_{i-1}}\\right)$$")),
      tags$li(HTML("Solve via the Thomas algorithm (forward sweep + back substitution).")),
      tags$li(HTML("Recover the remaining coefficients: $$b_i = \\tfrac{y_{i+1}-y_i}{h_i} - \\tfrac{h_i(2c_i + c_{i+1})}{3}, \\qquad d_i = \\tfrac{c_{i+1} - c_i}{3 h_i}$$"))
    ),
    tags$h3("Where it's used"),
    div(class = "apps-grid",
      div(class = "app-card", tags$h4("Computer Graphics"),
          tags$p("Smooth curves for fonts, vector illustration, and animation paths.")),
      div(class = "app-card", tags$h4(HTML("Engineering &amp; CAD")),
          tags$p("Designing aerodynamic shapes — wings, hulls, car bodies — from sparse points.")),
      div(class = "app-card", tags$h4("Data Science"),
          tags$p("Smooth missing-value imputation, monotone calibration curves, and signal resampling."))
    ),
    tags$h3("Conclusion"),
    tags$p(HTML(
      "Cubic spline interpolation is a clean answer to a hard problem: how to draw a smooth curve",
      "through data without the explosive oscillations that plague high-degree polynomials.",
      "By insisting on <strong>low-degree pieces</strong> (cubic on each interval) joined under",
      "<strong>$C^2$ continuity</strong>, the method trades a single global formula for a system",
      "that is both <em>visually faithful</em> and <em>numerically stable</em> &mdash; and the",
      "tridiagonal solve makes it cheap enough to run in real time on millions of points."
    )),
    tags$p(HTML(
      "The wider implication is methodological. Many problems in numerical analysis &mdash; root-finding,",
      "integration, ODE solving &mdash; share the same lesson: a globally-defined object often misbehaves,",
      "while a <strong>piecewise-local construction with smoothness conditions</strong> stays well-conditioned.",
      "Cubic splines made this idea concrete in interpolation; the same pattern reappears in finite-element",
      "methods, signal processing kernels, and modern machine-learning techniques (e.g., natural cubic",
      "splines as regression smoothers, monotone splines for calibration). Learning splines, then, isn't",
      "just learning interpolation &mdash; it's a first encounter with one of the most productive ideas",
      "in computational mathematics."
    )),
    div(class = "cta-row",
      tags$button(class = "btn btn-primary", id = "goto-calc-btn", type = "button",
                  HTML("Open the Calculator &rarr;"))
    )
  )
)

calc_panel <- tags$section(
  id = "calc", class = "panel", role = "tabpanel",
  div(class = "calc-grid",
    tags$aside(class = "card inputs-card",
      tags$h3("Inputs"),
      div(class = "field",
        tags$label(`for` = "boundary", "Boundary condition"),
        tags$select(id = "boundary",
          tags$option(value = "natural", selected = NA, HTML("Natural ($S''=0$ at ends)")),
          tags$option(value = "clamped", HTML("Clamped (specify end slopes)"))
        )
      ),
      div(id = "clamped-fields", class = "clamped-fields hidden",
        div(class = "field",
          tags$label(`for` = "fp-start", HTML("$f'(x_0)$")),
          tags$input(id = "fp-start", type = "number", step = "any", value = "0")
        ),
        div(class = "field",
          tags$label(`for` = "fp-end", HTML("$f'(x_n)$")),
          tags$input(id = "fp-end", type = "number", step = "any", value = "0")
        )
      ),
      div(class = "field",
        tags$label(HTML("Data points $(x_i, y_i)$")),
        div(class = "points-table-wrap",
          tags$table(class = "points-table", id = "points-table",
            tags$thead(tags$tr(
              tags$th("#"), tags$th("x"), tags$th("y"),
              tags$th(`aria-label` = "actions")
            )),
            tags$tbody(id = "points-tbody")
          )
        ),
        div(class = "row-actions",
          tags$button(class = "btn btn-ghost btn-sm", id = "add-row-btn", type = "button", "+ Add point"),
          tags$button(class = "btn btn-ghost btn-sm", id = "reset-points-btn", type = "button", "Reset")
        )
      ),
      div(class = "field",
        tags$label(`for` = "preset", "Quick presets"),
        tags$select(id = "preset",
          tags$option(value = "", HTML("&mdash; Choose a preset &mdash;")),
          tags$option(value = "runge", HTML("Runge function (1/(1+25x&sup2;))")),
          tags$option(value = "sine", "Sine wave samples"),
          tags$option(value = "textbook", HTML("Textbook example (e&#739;)")),
          tags$option(value = "temperature", "Daily temperature")
        )
      ),
      div(class = "field",
        tags$label(`for` = "eval-x", HTML("Predict $Y$ from $X$")),
        tags$input(id = "eval-x", type = "number", step = "any",
                   placeholder = "enter x, e.g. 1.5"),
        div(id = "predict-output", class = "predict-output", `aria-live` = "polite")
      ),
      tags$button(class = "btn btn-primary btn-block", id = "calc-btn", type = "button", "Compute Spline"),
      tags$p(class = "error-text", id = "error-text", role = "alert")
    ),
    div(class = "results",
      tags$nav(class = "subtabs", role = "tablist",
        tags$button(class = "subtab is-active", `data-subtab` = "plot", role = "tab",
                    `aria-selected` = "true", "Plot"),
        tags$button(class = "subtab", `data-subtab` = "steps", role = "tab",
                    `aria-selected` = "false", "Steps"),
        tags$button(class = "subtab", `data-subtab` = "table", role = "tab",
                    `aria-selected` = "false", "Coefficients"),
        tags$button(class = "subtab", `data-subtab` = "pieces", role = "tab",
                    `aria-selected` = "false", "Piecewise")
      ),
      div(id = "plot", class = "subpanel is-active", role = "tabpanel",
        div(class = "card",
          div(class = "chart-wrap", tags$canvas(id = "spline-chart")),
          tags$p(class = "caption", HTML(
            "The indigo curve is the cubic spline interpolant; white dots are the input data points. If you provided an evaluation $x$, the green marker shows $S(x)$ on the spline."
          ))
        )
      ),
      div(id = "steps", class = "subpanel", role = "tabpanel",
        div(id = "steps-output", class = "steps-output")
      ),
      div(id = "table", class = "subpanel", role = "tabpanel",
        div(class = "card",
          div(id = "coef-output"),
          tags$p(class = "caption", HTML(
            "Each row gives the coefficients of $S_i(x) = a_i + b_i(x - x_i) + c_i(x - x_i)^2 + d_i(x - x_i)^3$ valid on $[x_i, x_{i+1}]$."
          ))
        )
      ),
      div(id = "pieces", class = "subpanel", role = "tabpanel",
        div(id = "pieces-output", class = "pieces-output")
      )
    )
  )
)

ui <- tagList(
  tags$head(
    tags$meta(name = "description",
              content = "Cubic Spline Interpolation calculator with step-by-step solution, plot, and coefficient table."),
    tags$meta(name = "color-scheme", content = "dark"),
    tags$title("Cubic Spline Interpolation"),

    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(rel = "preconnect", href = "https://fonts.gstatic.com", crossorigin = NA),
    tags$link(rel = "stylesheet",
              href = "https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap"),

    tags$link(rel = "stylesheet", href = "style.css"),

    tags$style(HTML(paste(
      ":root{color-scheme:dark;}",
      "html{color-scheme:dark;scrollbar-color:#3f3f46 #09090b;scrollbar-width:thin;}",
      "::-webkit-scrollbar-track{background:#09090b !important;}",
      "::-webkit-scrollbar-corner{background:#09090b !important;}",
      sep = ""
    ))),

    tags$script(HTML(paste(
      "window.MathJax = {",
      "  tex: { inlineMath: [['$','$'],['\\\\(','\\\\)']],",
      "         displayMath: [['$$','$$'],['\\\\[','\\\\]']],",
      "         processEscapes: true },",
      "  svg: { fontCache: 'global' }",
      "};", sep = "\n"
    ))),
    tags$script(`async` = NA, src = "mathjax/tex-mml-chtml.js"),
    tags$script(src = "chart.umd.min.js")
  ),
  div(class = "app-root",
    tags$header(class = "site-header",
      div(class = "container header-row",
        div(class = "brand",
          div(class = "brand-mark", `aria-hidden` = "true",
            HTML('<svg viewBox="0 0 32 32" width="22" height="22"><path d="M2 24 C 8 4, 14 28, 20 12 S 28 6, 30 18" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/></svg>')
          ),
          div(class = "brand-text",
            tags$h1("Cubic Spline Interpolation"),
            tags$p("A smooth, piecewise-cubic curve through your data points.")
          )
        ),
        tags$nav(class = "tabs", role = "tablist",
          tags$button(class = "tab is-active", `data-tab` = "intro", role = "tab",
                      `aria-selected` = "true", "Introduction"),
          tags$button(class = "tab", `data-tab` = "calc", role = "tab",
                      `aria-selected` = "false", "Calculator")
        ),
        tags$a(class = "github-link",
               href = "https://en.wikipedia.org/wiki/Spline_interpolation",
               target = "_blank", rel = "noopener",
               HTML("Learn more &rarr;"))
      )
    ),
    tags$main(class = "container", intro_panel, calc_panel),
    tags$footer(class = "site-footer",
      div(class = "container",
        tags$p(tags$strong("Developed by Group 1")),
        tags$p(class = "muted",
               HTML("Final Activity &middot; Numerical Analysis &middot; &copy; "),
               tags$span(id = "year"))
      )
    ),
    tags$script(src = "app-client.js")
  )
)

# === HTML builders for Steps / Coefficients / Piecewise ===
# Build as plain HTML strings — pushed to the client via custom messages
# (avoids Shiny's output-binding code path, which proved unreliable in shinylive).

build_steps_html <- function(s) {
  n <- length(s$a); xs <- s$xs; ys <- s$ys; h <- s$h
  a <- s$a; b <- s$b; cc <- s$c; d <- s$d; tr <- s$trace

  step_block <- function(num, title, intro, lines) {
    div(class = "step-block",
      div(class = "step-header",
        tags$span(class = "step-num", sprintf("%02d", num)),
        tags$span(class = "step-title", HTML(title))
      ),
      div(class = "step-body",
        tags$p(class = "step-intro", HTML(intro)),
        lapply(lines, function(ln) div(class = "step-line", HTML(ln)))
      )
    )
  }

  blocks <- list(
    step_block(1, "Compute interval widths",
      "\\(h_i = x_{i+1} - x_i\\)",
      lapply(seq_len(n), function(i)
        sprintf("\\(h_{%d} = %s - %s = %s\\)",
                i - 1, fmt(xs[i + 1]), fmt(xs[i]), fmt(h[i])))),
    step_block(2, "Set the constant terms",
      "\\(a_i = y_i\\)",
      lapply(seq_len(n), function(i)
        sprintf("\\(a_{%d} = %s\\)", i - 1, fmt(a[i]))))
  )

  a_lines <- list()
  if (s$type == "clamped") {
    a_lines <- c(a_lines, list(
      sprintf("\\(\\alpha_{0} = \\dfrac{3(y_1 - y_0)}{h_0} - 3 f'(x_0) = %s\\)",
              fmt(tr$alpha[1])),
      sprintf("\\(\\alpha_{%d} = 3 f'(x_n) - \\dfrac{3(y_n - y_{n-1})}{h_{n-1}} = %s\\)",
              n, fmt(tr$alpha[n + 1]))
    ))
  }
  if (n >= 2) for (i in 2:n) {
    a_lines <- c(a_lines, list(sprintf(
      "\\(\\alpha_{%d} = \\dfrac{3(y_{%d} - y_{%d})}{h_{%d}} - \\dfrac{3(y_{%d} - y_{%d})}{h_{%d}} = %s\\)",
      i - 1, i, i - 1, i - 1, i - 1, i - 2, i - 2, fmt(tr$alpha[i]))))
  }
  blocks <- c(blocks, list(step_block(3, "Build the right-hand side",
    "Tridiagonal system: \\(h_{i-1}c_{i-1} + 2(h_{i-1}+h_i)c_i + h_i c_{i+1} = \\alpha_i\\)",
    a_lines)))

  sweep_lines <- lapply(seq_len(n + 1), function(i)
    sprintf("\\(i = %d: \\quad l_{%d} = %s, \\;\\; \\mu_{%d} = %s, \\;\\; z_{%d} = %s\\)",
            i - 1, i - 1, fmt(tr$l[i]), i - 1, fmt(tr$mu[i]), i - 1, fmt(tr$z[i])))
  blocks <- c(blocks, list(step_block(4, "Forward sweep (Thomas algorithm)",
    "Solve the tridiagonal system using LU decomposition.", sweep_lines)))

  c_lines <- lapply(seq_len(n + 1), function(i)
    sprintf("\\(c_{%d} = %s\\)", i - 1, fmt(tr$c_full[i])))
  blocks <- c(blocks, list(step_block(5, "Back-substitute for c<sub>i</sub>",
    "\\(c_i = z_i - \\mu_i \\, c_{i+1}\\)", c_lines)))

  bd_lines <- list()
  for (i in seq_len(n)) {
    bd_lines <- c(bd_lines, list(
      sprintf("\\(b_{%d} = \\dfrac{y_{%d} - y_{%d}}{h_{%d}} - \\dfrac{h_{%d}(c_{%d} + 2 c_{%d})}{3} = %s\\)",
              i - 1, i, i - 1, i - 1, i - 1, i, i - 1, fmt(b[i])),
      sprintf("\\(d_{%d} = \\dfrac{c_{%d} - c_{%d}}{3 h_{%d}} = %s\\)",
              i - 1, i, i - 1, i - 1, fmt(d[i]))
    ))
  }
  blocks <- c(blocks, list(step_block(6, "Compute the linear and cubic coefficients",
    "\\(b_i = \\dfrac{y_{i+1}-y_i}{h_i} - \\dfrac{h_i(c_{i+1}+2c_i)}{3}\\), \\(\\quad d_i = \\dfrac{c_{i+1}-c_i}{3 h_i}\\)",
    bd_lines)))

  as.character(do.call(tagList, blocks))
}

build_coef_html <- function(s) {
  n <- length(s$a)
  rows <- lapply(seq_len(n), function(i) {
    tags$tr(
      tags$td(i - 1),
      tags$td(fmt(s$xs[i])),
      tags$td(fmt(s$xs[i + 1])),
      tags$td(fmt(s$a[i])),
      tags$td(fmt(s$b[i])),
      tags$td(fmt(s$c[i])),
      tags$td(fmt(s$d[i]))
    )
  })
  tbl <- div(class = "table-scroll",
    tags$table(class = "coef-table", id = "coef-table",
      tags$thead(tags$tr(
        tags$th("i"),
        tags$th(HTML("\\(x_i\\)")),
        tags$th(HTML("\\(x_{i+1}\\)")),
        tags$th(HTML("\\(a_i\\)")),
        tags$th(HTML("\\(b_i\\)")),
        tags$th(HTML("\\(c_i\\)")),
        tags$th(HTML("\\(d_i\\)"))
      )),
      do.call(tags$tbody, rows)
    )
  )
  as.character(tbl)
}

build_predict_html <- function(s, x) {
  if (is.null(x) || !is.finite(x)) return("")
  xs <- s$xs
  if (x < xs[1] || x > xs[length(xs)]) {
    return(as.character(div(class = "predict-card predict-out-of-range",
      sprintf("x = %s is outside [%s, %s]",
              fmt(x), fmt(xs[1]), fmt(xs[length(xs)])))))
  }
  a <- s$a; b <- s$b; cc <- s$c; d <- s$d
  i <- 1
  while (i < length(a) && x > xs[i + 1]) i <- i + 1
  yq <- eval_spline(s, x)
  xq <- fmt(x, 4); xi <- fmt(xs[i])
  tex <- sprintf(
"\\[ \\begin{aligned}
S_{%d}(%s) ={}& %s \\\\
& %s\\, %s\\,(%s - %s) \\\\
& %s\\, %s\\,(%s - %s)^{2} \\\\
& %s\\, %s\\,(%s - %s)^{3} \\\\
={}& %s
\\end{aligned} \\]",
    i - 1, xq, fmt(a[i]),
    sgn(b[i]), fmt(abs(b[i])), xq, xi,
    sgn(cc[i]), fmt(abs(cc[i])), xq, xi,
    sgn(d[i]), fmt(abs(d[i])), xq, xi,
    fmt(yq, 6)
  )
  card <- div(class = "predict-card",
    div(class = "predict-meta",
      HTML(sprintf(
        "Uses piece <span class='predict-piece'>\\(S_{%d}\\)</span> on \\([%s,\\; %s]\\)",
        i - 1, fmt(xs[i]), fmt(xs[i + 1])
      ))
    ),
    div(class = "predict-eq", HTML(tex)),
    div(class = "predict-result",
      tags$span(class = "predict-label",
                HTML(sprintf("\\(S(%s) =\\)", xq))),
      tags$span(class = "predict-value", fmt(yq, 6))
    )
  )
  as.character(card)
}

build_pieces_html <- function(s) {
  n <- length(s$a); xs <- s$xs
  a <- s$a; b <- s$b; cc <- s$c; d <- s$d
  cards <- lapply(seq_len(n), function(i) {
    xi <- fmt(xs[i])
    tex <- sprintf(
"\\[ \\begin{aligned}
S_{%d}(x) ={}& %s \\\\
& %s\\, %s\\,(x - %s) \\\\
& %s\\, %s\\,(x - %s)^{2} \\\\
& %s\\, %s\\,(x - %s)^{3}
\\end{aligned} \\]",
      i - 1, fmt(a[i]),
      sgn(b[i]), fmt(abs(b[i])), xi,
      sgn(cc[i]), fmt(abs(cc[i])), xi,
      sgn(d[i]), fmt(abs(d[i])), xi
    )
    div(class = "piece-card",
      div(class = "piece-header",
        div(class = "piece-label",
          tags$span(class = "piece-badge", i),
          tags$span(class = "piece-name", "Piece")
        ),
        tags$span(class = "piece-interval",
                  HTML(sprintf("for \\(x \\in [%s,\\; %s]\\)",
                               fmt(xs[i]), fmt(xs[i + 1]))))
      ),
      div(class = "piece-eq", HTML(tex))
    )
  })
  as.character(do.call(tagList, cards))
}

# === Server ===
server <- function(input, output, session) {

  observeEvent(input$compute_request, {
    req <- input$compute_request
    pts <- req$points
    if (is.null(pts) || length(pts) == 0) return()

    xs <- vapply(pts, function(p) as.numeric(p$x), numeric(1))
    ys <- vapply(pts, function(p) as.numeric(p$y), numeric(1))
    ord <- order(xs); xs <- xs[ord]; ys <- ys[ord]

    if (length(xs) < 3) {
      session$sendCustomMessage("spline_result",
        list(error = "Cubic spline needs at least 3 points."))
      return()
    }
    if (any(diff(xs) == 0)) {
      session$sendCustomMessage("spline_result",
        list(error = sprintf("Duplicate x value: %s.", fmt(xs[which(diff(xs) == 0)[1]]))))
      return()
    }

    type <- if (is.null(req$type)) "natural" else as.character(req$type)
    fp0  <- if (is.null(req$fp0)) 0 else as.numeric(req$fp0)
    fpn  <- if (is.null(req$fpn)) 0 else as.numeric(req$fpn)

    s <- tryCatch(cubic_spline(xs, ys, type, fp0, fpn),
                  error = function(e) list(error = conditionMessage(e)))
    if (!is.null(s$error)) {
      session$sendCustomMessage("spline_result", list(error = s$error))
      return()
    }

    # Build curve for Chart.js (400 samples)
    x0 <- xs[1]; xn <- xs[length(xs)]
    grid <- seq(x0, xn, length.out = 400)
    y_grid <- vapply(grid, function(xq) eval_spline(s, xq), numeric(1))
    curve_pts <- lapply(seq_along(grid), function(k) list(x = grid[k], y = y_grid[k]))
    data_pts  <- lapply(seq_along(xs), function(k) list(x = xs[k], y = ys[k]))

    # Optional eval point
    eval_x <- req$evalX
    eval_pt  <- NULL
    predict_html <- ""
    if (!is.null(eval_x) && !is.na(suppressWarnings(as.numeric(eval_x)))) {
      xq <- as.numeric(eval_x)
      yq <- eval_spline(s, xq)
      if (!is.na(yq)) eval_pt <- list(x = xq, y = yq)
      predict_html <- build_predict_html(s, xq)
    }

    session$sendCustomMessage("spline_result", list(
      curve     = curve_pts,
      points    = data_pts,
      evalPoint = eval_pt,
      error     = NULL
    ))
    session$sendCustomMessage("steps_html",   list(html = build_steps_html(s)))
    session$sendCustomMessage("coef_html",    list(html = build_coef_html(s)))
    session$sendCustomMessage("pieces_html",  list(html = build_pieces_html(s)))
    session$sendCustomMessage("predict_html", list(html = predict_html))
  })
}

shinyApp(ui, server)
