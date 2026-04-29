# Cubic Spline Interpolation — Web App

A pure HTML / CSS / JavaScript web application that computes and visualizes
**natural** and **clamped cubic splines** through a user-supplied set of
data points.

## Features

- **Two boundary conditions** — natural ($S''=0$ at endpoints) and clamped ($S'$ specified at endpoints).
- **Editable data table** — add, remove, and edit $(x_i, y_i)$ points; presets included (Runge, sine, textbook example, daily temperature).
- **Live plot** — smooth spline curve overlaid with input points (Chart.js).
- **Step-by-step solution** — interval widths $h_i$, RHS $\alpha_i$, the Thomas-algorithm sweep ($l_i, \mu_i, z_i$), and back-substitution for $a_i, b_i, c_i, d_i$.
- **Coefficient table** — clean view of every $S_i(x)$ coefficient.
- **Piecewise expression view** — the full piecewise definition of $S(x)$.
- **Evaluate at arbitrary $x$** — value of $S(x)$ shown numerically and as a marker on the plot.
- **Mobile responsive** — sidebar collapses, tabs scroll, plot resizes.

## Algorithm

Implements the cubic-spline algorithm from _Numerical Analysis_ (Burden & Faires, §3.5):

1. $h_i = x_{i+1} - x_i$
2. $a_i = y_i$
3. $\alpha_i = \tfrac{3}{h_i}(y_{i+1}-y_i) - \tfrac{3}{h_{i-1}}(y_i - y_{i-1})$
4. Forward sweep (Thomas algorithm) for $l_i, \mu_i, z_i$
5. Back substitution: $c_i = z_i - \mu_i c_{i+1}$
6. $b_i = \tfrac{y_{i+1}-y_i}{h_i} - \tfrac{h_i (c_{i+1} + 2 c_i)}{3}$
7. $d_i = \tfrac{c_{i+1} - c_i}{3 h_i}$

## Numerical verification

The algorithm has been verified against **`scipy.interpolate.CubicSpline`**
across 5 test cases (textbook natural, textbook clamped, sine, Runge,
non-uniform spacing). Maximum coefficient error: **3.55 × 10⁻¹⁵**
(machine epsilon — i.e. the algorithm is mathematically exact).

To re-run the verification:

```bash
cd _verify
python3 verify.py    # requires numpy, scipy, and node
```

## Run locally

It's plain static HTML — open `index.html` in a browser, or:

```bash
python3 -m http.server 8000
# visit http://localhost:8000
```

## Deploy to Vercel

The project is 100% static, so Vercel auto-detects it.

```bash
npm i -g vercel
vercel
# follow prompts; subsequent deploys: `vercel --prod`
```

Or push to GitHub and import the repo on [vercel.com/new](https://vercel.com/new) — no build settings needed.

## File structure

```
.
├── index.html         # markup, MathJax + Chart.js CDNs
├── style.css          # design tokens, responsive layout
├── script.js          # spline algorithm + UI logic
├── vercel.json        # (optional) clean URLs config
├── README.md
└── _verify/           # numerical-correctness harness (not deployed)
    ├── spline_algo.js
    ├── run_js.js
    └── verify.py
```

