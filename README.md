# Cubic Spline Interpolation

R Shiny calculator for **natural** and **clamped** cubic splines, implementing
Burden & Faires §3.5. Editable points, live plot, step-by-step LaTeX solution,
piecewise expressions, predict-Y, and a "Hear Your Spline" audio playback that
maps the curve's height to pitch over time.

[Live demo](https://cubic-splines.vercel.app)

## Run it

Two options, same UI.

### Prerequisites — install R (one-time)

**macOS** — easiest is RStudio Desktop, which bundles both R and the IDE:

1. Install R: download from <https://cran.r-project.org/bin/macosx/> (or `brew install --cask r`)
2. Install RStudio: <https://posit.co/download/rstudio-desktop/>

**Windows:**

1. Install R: download from <https://cran.r-project.org/bin/windows/base/> and run the `.exe`
2. Install RStudio: <https://posit.co/download/rstudio-desktop/>

Then install the `shiny` package (one-time, in any R/RStudio console):

```r
install.packages("shiny")
```

### A. Single-file R Shiny (simplest, for submission)

Once R is installed, three equivalent ways to run:

**1. One-command script** (auto-installs `shiny` and launches the app):

```bash
./run.sh          # macOS / Linux
run.bat           # Windows (or just double-click)
```

**2. RStudio:** open `FinalActivity_deJesusLimPumarManaliliSingh.R` → click **Run App**.

**3. Terminal:**

```bash
Rscript -e 'shiny::runApp("FinalActivity_deJesusLimPumarManaliliSingh.R", launch.browser=TRUE)'
```

Loads Chart.js and MathJax from CDN (needs internet on first run; cached after).

### B. Multi-file R Shiny (offline, fully vendored)

```bash
Rscript -e 'install.packages(c("shiny","DT"), repos="https://cloud.r-project.org")'
Rscript -e 'shiny::runApp("app", launch.browser=TRUE)'
```

### C. No R install — open the deployed bundle

```bash
cd dist && python3 -m http.server 8000      # http://localhost:8000
```

R runs entirely in the browser via WebAssembly (shinylive). First load
~10–30s; cached after.

## Algorithm

1. $h_i = x_{i+1} - x_i$
2. $a_i = y_i$
3. $\alpha_i = \tfrac{3}{h_i}(y_{i+1}-y_i) - \tfrac{3}{h_{i-1}}(y_i - y_{i-1})$
4. Forward sweep (Thomas) for $l_i, \mu_i, z_i$
5. Back-substitute: $c_i = z_i - \mu_i c_{i+1}$
6. $b_i = \tfrac{y_{i+1}-y_i}{h_i} - \tfrac{h_i(c_{i+1}+2c_i)}{3}$, $\;\;d_i = \tfrac{c_{i+1}-c_i}{3 h_i}$

## Verification

Both R and JS implementations are checked against `scipy.interpolate.CubicSpline`
across 5 test cases (textbook natural, textbook clamped, sine, Runge, non-uniform).

| Comparison  | Max coefficient error | Status    |
| ----------- | --------------------- | --------- |
| R vs scipy  | 3.55 × 10⁻¹⁵          | machine ε |
| JS vs scipy | 3.55 × 10⁻¹⁵          | machine ε |
| R vs JS     | 1.11 × 10⁻¹⁶ on sine  | bit-exact |

```bash
cd _verify && python3 verify.py && python3 verify_r.py
```

## Build / deploy

Single-file R is regenerated from `app/` + `style.css` + `app/www/app-client.js`:

```bash
Rscript build_singlefile.R
```

Vercel build (shinylive WebAssembly bundle):

```bash
Rscript build.R              # produces dist/
```

`vercel.json` deploys `dist/` as static files; webR runs the R code in the
browser. First load downloads ~30 MB of WASM and is cached.

## Layout

```
.
├── FinalActivity_deJesusLimPumarManaliliSingh.R   # single-file submission
├── build_singlefile.R                              # rebuilds the single-file
├── build.R                                         # rebuilds dist/ (shinylive)
├── app/
│   ├── app.R                                       # Shiny UI + server
│   └── www/                                        # vendored CSS / JS / Chart.js / MathJax
├── dist/                                           # shinylive output (Vercel)
├── _verify/                                        # numerical correctness harness
├── style.css, favicon.svg                          # source assets shared by app/www and the build scripts
└── vercel.json
```
