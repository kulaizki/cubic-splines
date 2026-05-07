# Cubic Spline Interpolation — R Shiny App

An R Shiny application that computes and visualizes **natural** and
**clamped cubic splines** through a user-supplied set of data points.
Modeled after the example Shiny submission, but implementing the cubic
spline algorithm from _Numerical Analysis_ (Burden & Faires, §3.5).

## Features

- **Two boundary conditions** — natural ($S''=0$ at endpoints) and clamped ($S'$ specified at endpoints).
- **Editable data points** — paste/edit `x, y` pairs in the textarea, or pick a preset (Runge, sine, textbook example, daily temperature).
- **Live plot** — smooth spline curve overlaid with input points (base R graphics).
- **Step-by-step solution** — interval widths $h_i$, RHS $\alpha_i$, the Thomas-algorithm sweep ($l_i, \mu_i, z_i$), and back-substitution for $a_i, b_i, c_i, d_i$.
- **Coefficient table** — `DT::datatable` view of every $S_i(x)$ coefficient.
- **Piecewise expression view** — full piecewise definition of $S(x)$ via MathJax.
- **Evaluate at arbitrary $x$** — value of $S(x)$ shown numerically and as a marker on the plot.

## Algorithm

1. $h_i = x_{i+1} - x_i$
2. $a_i = y_i$
3. $\alpha_i = \tfrac{3}{h_i}(y_{i+1}-y_i) - \tfrac{3}{h_{i-1}}(y_i - y_{i-1})$
4. Forward sweep (Thomas algorithm) for $l_i, \mu_i, z_i$
5. Back substitution: $c_i = z_i - \mu_i c_{i+1}$
6. $b_i = \tfrac{y_{i+1}-y_i}{h_i} - \tfrac{h_i (c_{i+1} + 2 c_i)}{3}$
7. $d_i = \tfrac{c_{i+1} - c_i}{3 h_i}$

## Numerical verification

Both the R and JavaScript implementations are verified against
`scipy.interpolate.CubicSpline` (the SciPy reference) and against each
other, across 5 test cases (textbook natural, textbook clamped, sine,
Runge, non-uniform spacing).

| Comparison  | Max coefficient error                              | Status      |
| ----------- | -------------------------------------------------- | ----------- |
| R vs scipy  | 3.55 × 10⁻¹⁵                                       | ✓ machine ε |
| JS vs scipy | 3.55 × 10⁻¹⁵                                       | ✓ machine ε |
| R vs JS     | bit-exact on most coeffs; max 1.11 × 10⁻¹⁶ on sine | ✓           |

To re-run the verifications:

```bash
cd _verify
python3 verify.py     # JS  vs scipy
python3 verify_r.py   # R   vs scipy   (needs R + jsonlite)
```

## Run locally (RStudio)

1. Open `app/app.R` in RStudio.
2. Click **Run App** (or `shiny::runApp("app")` from the R console).

Required packages:

```r
install.packages(c("shiny", "DT"))
```

## Deploy

Shiny apps need an R runtime, but Vercel doesn't have one. We use
**[shinylive](https://posit-dev.github.io/r-shinylive/)** to compile the
app to a fully static bundle (Shiny + WebAssembly), which Vercel can
serve directly.

### One-time setup

```r
install.packages("shinylive")
```

### Build static bundle

From the project root:

```bash
Rscript -e "shinylive::export('app', 'dist')"
```

This produces a `dist/` folder containing `index.html`,
`shinylive-sw.js`, the WebAssembly runtime, and your app code. It is
fully self-contained and offline-capable after first load.

### Deploy to Vercel

The `vercel.json` is already wired up — `outputDirectory` points at
`dist/`, with COOP/COEP headers so shinylive's WebAssembly loader gets
optimal performance.

Two ways to deploy:

**A. Via Vercel CLI** (re-deploy after each `dist/` rebuild)

```bash
npm i -g vercel
vercel --prod
```

**B. Via GitHub** (commit `dist/` to main)

```bash
Rscript -e "shinylive::export('app', 'dist')"
git add dist
git commit -m "build: regenerate shinylive bundle"
git push
```

Vercel auto-deploys on push.

> **Note on first load:** shinylive bootstraps webR (an R-in-WebAssembly
> runtime) in the browser. Expect ~10–30s on first load while ~30 MB of
> WASM is downloaded and cached. Subsequent loads are near-instant.

### Alternative host: shinyapps.io

If you'd rather run a real R server (no shinylive, instant first load):

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(name = "<your-account>", token = "...", secret = "...")
rsconnect::deployApp("app")
```

## File structure

```
.
├── app/
│   └── app.R              # the Shiny app (UI + server)
├── dist/                  # shinylive build output (deployed to Vercel)
├── vercel.json            # outputDirectory + COOP/COEP headers
├── README.md
├── _verify/               # numerical correctness harness for the JS port
│   ├── spline_algo.js
│   ├── run_js.js
│   └── verify.py
└── (legacy static port)   # original HTML/CSS/JS — not deployed
    ├── index.html
    ├── style.css
    └── script.js
```
