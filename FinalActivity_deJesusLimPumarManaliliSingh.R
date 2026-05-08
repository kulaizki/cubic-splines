# ==============================================================
# Cubic Spline Interpolation — single-file R Shiny app
# Run:  Rscript -e 'shiny::runApp("FinalActivity_deJesusLimPumarManaliliSingh.R", launch.browser = TRUE)'
# Or open in RStudio and click Run App.
# Requires: install.packages('shiny')
# Loads Chart.js and MathJax from CDN (needs internet on first run).
# ==============================================================

library(shiny)

APP_CSS <- r"------(
/* ================== Design tokens (dark) ================== */
:root {
  --bg: #09090b;
  --bg-2: #18181b;
  --bg-3: #27272a;
  --surface: #18181b;
  --border: #27272a;
  --border-strong: #3f3f46;

  --text: #fafafa;
  --text-muted: #a1a1aa;
  --text-tertiary: #71717a;

  --accent: #818cf8;
  --accent-hover: #a5b4fc;
  --accent-soft: rgba(129, 140, 248, 0.12);

  --success: #34d399;
  --danger: #f87171;
  --warn: #fbbf24;

  --radius: 10px;
  --radius-sm: 6px;

  --font-sans:
    "Manrope", system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  --font-mono:
    "JetBrains Mono", ui-monospace, Menlo, Monaco, Consolas, monospace;
}

* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  padding: 0;
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-sans);
  font-size: 16px;
  line-height: 1.6;
  font-variant-ligatures: no-contextual;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  /* `clip` instead of `hidden` — `hidden` breaks position:sticky on descendants */
  overflow-x: clip;
  max-width: 100vw;
}
img,
svg {
  max-width: 100%;
}

::selection {
  background: var(--accent-soft);
  color: var(--accent);
}

::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}
::-webkit-scrollbar-track {
  background: transparent;
}
::-webkit-scrollbar-thumb {
  background: var(--border-strong);
  border-radius: 4px;
}
::-webkit-scrollbar-thumb:hover {
  background: var(--text-tertiary);
}

h1,
h2,
h3,
h4 {
  color: var(--text);
  margin: 0 0 0.5em;
  line-height: 1.25;
  letter-spacing: -0.01em;
}
h1 {
  font-size: clamp(1.4rem, 2.5vw, 1.65rem);
  font-weight: 600;
}
h2 {
  font-size: clamp(1.4rem, 2.2vw, 1.65rem);
  font-weight: 700;
  letter-spacing: -0.02em;
  position: relative;
  padding-bottom: 14px;
  margin-bottom: 0.8em;
  border-bottom: 1px solid var(--border);
}
h2::after {
  content: "";
  position: absolute;
  bottom: -1px;
  left: 0;
  width: 44px;
  height: 2px;
  background: var(--accent);
  border-radius: 1px;
}
h3 {
  font-size: 1.12rem;
  font-weight: 600;
  margin-top: 2em;
  margin-bottom: 0.7em;
  display: flex;
  align-items: center;
  gap: 10px;
}
h3::before {
  content: "";
  display: inline-block;
  width: 3px;
  height: 16px;
  background: var(--accent);
  border-radius: 1.5px;
  flex-shrink: 0;
}
/* No leading whitespace when an h3 is the first thing inside a card */
.card > h3:first-child,
.card > h2:first-child,
.card > h4:first-child {
  margin-top: 0;
}
h4 {
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--text);
}
p {
  margin: 0 0 0.9em;
  color: var(--text);
}
p.lead {
  font-size: 1.06rem;
  line-height: 1.65;
  color: var(--text);
  margin-bottom: 1em;
}
ul,
ol {
  margin: 0 0 0.85em;
  padding-left: 1.3em;
  color: var(--text);
}
li {
  margin-bottom: 4px;
}
strong {
  color: var(--text);
  font-weight: 600;
}
em {
  color: var(--accent-hover);
  font-style: italic;
  font-weight: 500;
}
a {
  color: var(--accent);
  text-decoration: none;
  transition: color 0.15s ease;
}
a:hover {
  color: var(--accent-hover);
}
code,
kbd {
  font-family: var(--font-mono);
  font-size: 0.86em;
  background: var(--bg-2);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: 1px 6px;
  color: var(--accent-hover);
}
.eyebrow {
  display: inline-block;
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  color: var(--accent);
  background: var(--accent-soft);
  padding: 4px 10px;
  border-radius: 4px;
  margin-bottom: 14px;
  border: 1px solid rgba(129, 140, 248, 0.22);
}

/* Hide number input spinners */
input[type="number"]::-webkit-outer-spin-button,
input[type="number"]::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
input[type="number"] {
  -moz-appearance: textfield;
  appearance: textfield;
}

.container {
  width: 100%;
  max-width: 1500px;
  margin: 0 auto;
  padding: 0 32px;
}

/* ================== Header ================== */
.site-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(9, 9, 11, 0.82);
  backdrop-filter: saturate(180%) blur(14px);
  -webkit-backdrop-filter: saturate(180%) blur(14px);
  border-bottom: 1px solid var(--border);
  padding: 18px 0;
}
.header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
  min-width: 0;
}
.brand {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
  flex: 1 1 auto;
}
.brand-mark {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: 8px;
  background: var(--bg-2);
  border: 1px solid var(--border-strong);
  color: var(--accent);
  flex-shrink: 0;
}
.brand-text {
  min-width: 0;
  flex: 1 1 auto;
}
.brand-text h1 {
  margin: 0;
  word-break: break-word;
}
.brand-text p {
  margin: 2px 0 0;
  color: var(--text-muted);
  font-size: 0.9rem;
  word-break: break-word;
}
.github-link {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--text-muted);
  padding: 7px 14px;
  border-radius: 6px;
  border: 1px solid var(--border-strong);
  background: var(--bg-2);
  transition:
    border-color 0.15s ease,
    color 0.15s ease;
}
.github-link:hover {
  color: var(--accent);
  border-color: var(--accent);
  text-decoration: none;
}

/* ================== Tabs (inline pills in header) ================== */
.tabs {
  display: flex;
  gap: 4px;
  padding: 4px;
  background: var(--bg-2);
  border: 1px solid var(--border);
  border-radius: 8px;
  flex-shrink: 0;
}
.tab {
  background: transparent;
  border: none;
  padding: 7px 14px;
  font: inherit;
  font-weight: 500;
  font-size: 0.88rem;
  color: var(--text-muted);
  cursor: pointer;
  border-radius: 5px;
  white-space: nowrap;
  transition:
    color 0.15s ease,
    background 0.15s ease;
}
.tab:hover {
  color: var(--text);
}
.tab.is-active {
  color: var(--text);
  background: var(--bg-3);
  font-weight: 600;
}

.panel {
  display: none;
  padding: 28px 0 60px;
}
.panel.is-active {
  display: block;
  animation: fadeIn 0.25s ease;
}
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(4px);
  }
  to {
    opacity: 1;
    transform: none;
  }
}

/* ================== Card ================== */
.card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 28px;
  min-width: 0;
}
.card + .card {
  margin-top: 18px;
}

/* ================== Intro page ================== */
#intro .card {
  max-width: 880px;
  margin: 0 auto;
}
#intro .math-block {
  text-align: center;
  padding: 14px 18px;
  background: var(--bg-2);
  border: 1px solid var(--border);
  border-left: 3px solid var(--accent);
  border-radius: var(--radius-sm);
  margin: 14px 0 18px;
  overflow-x: auto;
  position: relative;
  font-size: 1.05em;
}
.conditions {
  list-style: none;
  padding-left: 0;
}
.conditions > li {
  position: relative;
  padding: 6px 0 6px 22px;
  margin-bottom: 4px;
}
.conditions > li::before {
  content: "";
  position: absolute;
  left: 4px;
  top: 14px;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent);
  opacity: 0.7;
}
.conditions ul {
  list-style: disc;
  margin-top: 6px;
  padding-left: 1.2em;
  color: var(--text);
}
.conditions strong {
  color: var(--text);
}

.algo {
  list-style: none;
  counter-reset: step;
  padding-left: 0;
}
.algo > li {
  counter-increment: step;
  position: relative;
  padding: 10px 0 10px 44px;
  margin-bottom: 6px;
  color: var(--text);
}
.algo > li::before {
  content: counter(step);
  position: absolute;
  left: 0;
  top: 8px;
  display: grid;
  place-items: center;
  width: 28px;
  height: 28px;
  background: var(--accent-soft);
  color: var(--accent);
  font-family: var(--font-mono);
  font-size: 0.82rem;
  font-weight: 700;
  border-radius: 6px;
  border: 1px solid rgba(129, 140, 248, 0.25);
}

.apps-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 14px;
  margin: 12px 0 24px;
}
.app-card {
  padding: 18px;
  background: var(--bg-2);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  transition:
    border-color 0.15s ease,
    transform 0.15s ease;
}
.app-card:hover {
  border-color: var(--accent);
  transform: translateY(-2px);
}
.app-card h4 {
  margin: 0 0 6px;
  color: var(--accent);
  font-size: 0.95rem;
  display: flex;
  align-items: center;
  gap: 8px;
}
.app-card h4::before {
  content: "";
  display: inline-block;
  width: 5px;
  height: 5px;
  background: var(--accent);
  border-radius: 50%;
}
.app-card p {
  margin: 0;
  color: var(--text-muted);
  font-size: 0.88rem;
  line-height: 1.55;
}
.cta-row {
  display: flex;
  justify-content: center;
  margin-top: 24px;
}

/* ================== Calculator layout ================== */
.calc-grid {
  display: grid;
  grid-template-columns: 400px minmax(0, 1fr);
  gap: 24px;
  align-items: start;
}
.inputs-card {
  position: sticky;
  top: 16px;
}
.results {
  min-width: 0;
}

/* ================== Form fields ================== */
.field {
  margin-bottom: 16px;
}
.field label {
  display: block;
  font-weight: 500;
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-bottom: 6px;
}
.field input[type="number"],
.field input[type="text"],
.field select {
  width: 100%;
  padding: 9px 12px;
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-sm);
  font: inherit;
  font-size: 0.92rem;
  background: var(--bg);
  color: var(--text);
  transition:
    border-color 0.15s ease,
    box-shadow 0.15s ease;
}
.field input::placeholder {
  color: var(--text-tertiary);
}
.field input:focus,
.field select:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 3px var(--accent-soft);
}
.field select {
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'%3E%3Cpath fill='%23a1a1aa' d='M0 0l5 6 5-6z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
  padding-right: 32px;
}
.clamped-fields {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.clamped-fields.hidden {
  display: none;
}

/* Points table */
.points-table-wrap {
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-sm);
  background: var(--bg);
  overflow: hidden;
}
.points-table {
  width: 100%;
  border-collapse: collapse;
  table-layout: fixed;
  font-size: 0.9rem;
}
.points-table thead th {
  background: var(--bg-2);
  text-align: left;
  padding: 8px 8px;
  font-weight: 500;
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-tertiary);
  border-bottom: 1px solid var(--border-strong);
}
.points-table thead th:first-child {
  width: 30px;
  padding-left: 12px;
}
.points-table thead th:last-child {
  width: 32px;
}
.points-table td {
  padding: 0;
  border-bottom: 1px solid var(--border);
}
.points-table td:first-child {
  padding: 0 4px 0 12px;
  color: var(--text-tertiary);
  width: 30px;
  font-family: var(--font-mono);
  font-size: 0.82rem;
  text-align: left;
}
.points-table td:last-child {
  width: 32px;
  text-align: center;
  padding: 0 4px;
}
.points-table tr:last-child td {
  border-bottom: none;
}
.points-table input[type="number"] {
  width: 100%;
  display: block;
  padding: 8px 6px;
  border: none;
  background: transparent;
  font: inherit;
  font-family: var(--font-mono);
  font-size: 0.86rem;
  border-radius: 0;
  color: var(--text);
  text-overflow: ellipsis;
}
.points-table input[type="number"]:focus {
  outline: none;
  background: var(--accent-soft);
  color: var(--text);
}
.row-del {
  background: transparent;
  border: none;
  color: var(--text-tertiary);
  cursor: pointer;
  font-size: 1.05rem;
  padding: 4px 8px;
  border-radius: 4px;
  transition:
    color 0.15s ease,
    background 0.15s ease;
}
.row-del:hover {
  color: var(--danger);
  background: rgba(248, 113, 113, 0.1);
}
.row-actions {
  display: flex;
  gap: 8px;
  margin-top: 10px;
}

/* ================== Prediction card ================== */
.predict-output {
  margin-top: 10px;
  min-height: 1em;
}
.predict-output:empty {
  margin-top: 0;
  min-height: 0;
}
/* Drop the trailing margin so the inputs card hugs its last element */
.inputs-card > .field:last-child,
.inputs-card > p:last-child {
  margin-bottom: 0;
}
.predict-card {
  background: var(--bg-2);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 14px 16px;
}
.predict-meta {
  color: var(--text-muted);
  font-size: 0.82rem;
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px dashed var(--border);
}
.predict-piece {
  color: var(--accent);
  font-family: var(--font-mono);
  font-weight: 600;
}
.predict-eq {
  font-family: var(--font-mono);
  font-size: 0.8rem;
  margin: 4px 0 12px;
  padding: 8px 4px;
  overflow-x: auto;
  color: var(--text);
}
.predict-eq mjx-container {
  text-align: left !important;
  margin: 0 !important;
}
.predict-result {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  padding: 10px 12px;
  background: var(--accent-soft);
  border: 1px solid rgba(129, 140, 248, 0.22);
  border-radius: var(--radius-sm);
}
.predict-label {
  color: var(--text-muted);
  font-size: 0.85rem;
  font-family: var(--font-mono);
}
.predict-value {
  color: var(--accent);
  font-weight: 700;
  font-size: 1.1rem;
  font-family: var(--font-mono);
}
.predict-card.predict-out-of-range {
  color: var(--danger);
  background: rgba(248, 113, 113, 0.08);
  border-color: rgba(248, 113, 113, 0.3);
  text-align: center;
  font-family: var(--font-mono);
  font-size: 0.85rem;
}

/* ================== Compute hint copy ================== */
.actions-hint {
  margin: 6px 0 10px;
  color: var(--text-muted);
  font-size: 0.78rem;
  line-height: 1.45;
}
.actions-hint strong {
  color: var(--text);
  font-weight: 600;
}

/* ================== Plot overlays: info tooltip + playhead canvas ================== */
#playhead-overlay {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 2;
}
.info-tooltip {
  position: absolute;
  top: 12px;
  right: 14px;
  z-index: 6;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: rgba(24, 24, 27, 0.65);
  border: 1px solid var(--border);
  color: var(--text-muted);
  cursor: help;
  outline: none;
  transition:
    color 0.15s ease,
    border-color 0.15s ease;
}
.info-tooltip:hover,
.info-tooltip:focus {
  color: var(--accent);
  border-color: var(--accent);
}
.info-glyph {
  display: block;
}
.info-content {
  position: absolute;
  top: calc(100% + 8px);
  right: 0;
  width: 280px;
  padding: 12px 14px;
  background: var(--surface);
  border: 1px solid var(--border-strong);
  border-radius: var(--radius-sm);
  font-size: 0.82rem;
  line-height: 1.5;
  color: var(--text-muted);
  font-weight: 400;
  cursor: default;
  opacity: 0;
  pointer-events: none;
  transform: translateY(-4px);
  transition:
    opacity 0.15s ease,
    transform 0.15s ease;
  box-shadow: 0 6px 24px rgba(0, 0, 0, 0.4);
}
.info-tooltip:hover .info-content,
.info-tooltip:focus .info-content,
.info-tooltip:focus-within .info-content {
  opacity: 1;
  pointer-events: auto;
  transform: translateY(0);
}

/* ================== Plot controls (Play button below the chart) ================== */
.plot-controls {
  display: flex;
  justify-content: center;
  padding: 14px 0 4px;
}
.plot-play-btn {
  width: 44px;
  height: 44px;
  padding: 0;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-2);
  border: 1px solid var(--border-strong);
  color: var(--accent);
  cursor: pointer;
  transition:
    background 0.15s ease,
    border-color 0.15s ease,
    transform 0.1s ease;
}
.plot-play-btn:not(:disabled):hover {
  background: var(--bg-3);
  border-color: var(--accent);
}
.plot-play-btn:not(:disabled):active {
  transform: scale(0.95);
}
.plot-play-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  color: var(--text-muted);
}
.plot-play-btn .play-glyph {
  display: block;
}
.plot-play-btn .stop-icon {
  display: none;
}
.plot-play-btn.is-playing .play-icon {
  display: none;
}
.plot-play-btn.is-playing .stop-icon {
  display: block;
}
.plot-play-btn.is-playing {
  border-color: #f472b6;
  color: #f472b6;
  animation: plot-play-pulse 1.4s ease-in-out infinite;
}
.plot-play-btn.is-playing:not(:disabled):hover {
  border-color: #f472b6;
  background: var(--bg-3);
}
@keyframes plot-play-pulse {
  0%,
  100% {
    box-shadow: 0 0 0 0 rgba(244, 114, 182, 0.45);
  }
  50% {
    box-shadow: 0 0 0 8px rgba(244, 114, 182, 0);
  }
}

/* ================== Buttons ================== */
.btn {
  display: inline-block;
  padding: 9px 16px;
  font: inherit;
  font-size: 0.9rem;
  font-weight: 500;
  border-radius: var(--radius-sm);
  border: 1px solid transparent;
  cursor: pointer;
  transition:
    background 0.15s ease,
    color 0.15s ease,
    border-color 0.15s ease,
    transform 0.05s ease;
  text-align: center;
}
.btn:active {
  transform: translateY(1px);
}
.btn-primary {
  background: var(--accent);
  color: var(--bg);
  font-weight: 600;
}
.btn-primary:hover {
  background: var(--accent-hover);
}
.btn-ghost {
  background: var(--bg-2);
  color: var(--text-muted);
  border-color: var(--border-strong);
}
.btn-ghost:hover {
  color: var(--text);
  border-color: var(--text-tertiary);
}
.btn-block {
  width: 100%;
}
.btn-sm {
  padding: 7px 12px;
  font-size: 0.84rem;
}

.error-text {
  margin: 12px 0 0;
  color: var(--danger);
  font-size: 0.88rem;
  min-height: 1em;
}

/* ================== Subtabs ================== */
.subtabs {
  display: flex;
  gap: 4px;
  margin-bottom: 16px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 4px;
  overflow-x: auto;
}
.subtab {
  background: transparent;
  border: none;
  padding: 7px 14px;
  font: inherit;
  font-weight: 500;
  font-size: 0.88rem;
  color: var(--text-muted);
  cursor: pointer;
  border-radius: 4px;
  white-space: nowrap;
  transition: all 0.15s ease;
}
.subtab:hover {
  color: var(--text);
}
.subtab.is-active {
  background: var(--bg-3);
  color: var(--accent);
}

.subpanel {
  display: none;
}
.subpanel.is-active {
  display: block;
  animation: fadeIn 0.25s ease;
}

/* ================== Plot ================== */
.chart-wrap {
  position: relative;
  width: 100%;
  height: 460px;
}
@media (max-width: 600px) {
  .chart-wrap {
    height: 360px;
  }
}

.caption {
  margin: 14px 0 0;
  color: var(--text-muted);
  font-size: 0.88rem;
  line-height: 1.55;
}

/* ================== Steps ================== */
.steps-output {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.step-block {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  overflow: hidden;
}
.step-header {
  background: var(--bg-2);
  color: var(--text);
  padding: 12px 18px;
  border-bottom: 1px solid var(--border);
  display: flex;
  align-items: center;
  gap: 12px;
}
.step-num {
  display: inline-grid;
  place-items: center;
  width: 30px;
  height: 30px;
  background: var(--accent-soft);
  color: var(--accent);
  font-family: var(--font-mono);
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.02em;
  border-radius: 6px;
  border: 1px solid rgba(129, 140, 248, 0.25);
  flex-shrink: 0;
}
.step-title {
  font-size: 0.98rem;
  font-weight: 600;
  color: var(--text);
  letter-spacing: -0.005em;
}
.step-body {
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  overflow-x: auto;
}
.step-intro {
  margin: 0 0 8px;
  padding: 8px 12px;
  background: var(--bg-2);
  border-left: 2px solid var(--border-strong);
  border-radius: 0 4px 4px 0;
  color: var(--text-muted);
  font-size: 0.9rem;
}
.step-line {
  font-size: 0.95rem;
  color: var(--text);
  padding: 4px 10px;
  border-radius: 4px;
  transition: background 0.15s ease;
}
.step-line:hover {
  background: var(--bg-2);
}

/* ================== Coefficients table ================== */
.table-scroll {
  overflow-x: auto;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-strong);
}
.coef-table {
  width: 100%;
  border-collapse: collapse;
  font-family: var(--font-mono);
  font-size: 0.85rem;
}
.coef-table th,
.coef-table td {
  padding: 10px 14px;
  text-align: right;
  border-bottom: 1px solid var(--border);
  white-space: nowrap;
  color: var(--text);
}
.coef-table th {
  background: var(--bg-2);
  font-family: var(--font-sans);
  font-weight: 500;
  color: var(--text-tertiary);
  font-size: 0.78rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  position: sticky;
  top: 0;
  border-bottom: 1px solid var(--border-strong);
}
.coef-table th:first-child,
.coef-table td:first-child {
  text-align: center;
  color: var(--text-tertiary);
}
.coef-table tbody tr:hover {
  background: var(--bg-2);
}
.coef-table tbody tr:last-child td {
  border-bottom: none;
}

/* ================== Piecewise ================== */
.pieces-output {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.piece-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  transition: border-color 0.15s ease;
}
.piece-card:hover {
  border-color: var(--border-strong);
}
.piece-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  flex-wrap: wrap;
  font-size: 0.85rem;
  color: var(--text-tertiary);
  border-bottom: 1px solid var(--border);
  padding-bottom: 10px;
  margin-bottom: 6px;
}
.piece-label {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}
.piece-badge {
  display: inline-grid;
  place-items: center;
  min-width: 26px;
  height: 24px;
  padding: 0 8px;
  background: var(--accent-soft);
  color: var(--accent);
  font-family: var(--font-mono);
  font-size: 0.78rem;
  font-weight: 700;
  border-radius: 5px;
  border: 1px solid rgba(129, 140, 248, 0.25);
}
.piece-name {
  color: var(--text);
  font-weight: 600;
  font-size: 0.92rem;
  letter-spacing: -0.005em;
}
.piece-interval {
  font-size: 0.85rem;
  color: var(--text-tertiary);
}
.piece-eq {
  font-size: 0.95rem;
  color: var(--text);
  overflow-x: auto;
  padding: 2px 0;
}

/* MathJax */
mjx-container {
  color: inherit !important;
  max-width: 100%;
}
mjx-container[display="true"] {
  margin: 0.4em 0 !important;
  display: block !important;
  overflow-x: auto;
  overflow-y: hidden;
}
.algo li mjx-container[display="true"],
.conditions li mjx-container[display="true"] {
  display: block !important;
  margin: 0.6em 0 !important;
  padding: 8px 0;
}

/* ================== Footer ================== */
.site-footer {
  border-top: 1px solid var(--border);
  background: var(--bg);
  padding: 24px 0;
  margin-top: 40px;
  text-align: center;
}
.site-footer p {
  margin: 2px 0;
  color: var(--text-muted);
  font-size: 0.9rem;
}
.site-footer strong {
  color: var(--text);
  font-weight: 600;
}
.muted {
  color: var(--text-tertiary);
  font-size: 0.82rem;
}

/* ================== Responsive ================== */
@media (max-width: 880px) {
  .calc-grid {
    grid-template-columns: 1fr;
  }
  .inputs-card {
    position: static;
  }
  .panel {
    padding: 20px 0 40px;
  }
  .card {
    padding: 22px;
  }
  .header-row {
    flex-direction: column;
    align-items: flex-start;
  }
  .github-link {
    align-self: flex-end;
  }
}
@media (max-width: 600px) {
  .container {
    padding: 0 16px;
  }
  .site-header {
    padding: 12px 0;
  }
  /* Compact one-row header: icon + tabs only. Hide title/subtitle and learn-more. */
  .header-row {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
  }
  .brand {
    flex: 0 0 auto;
    gap: 0;
    min-width: 0;
    align-items: center;
  }
  /* Pin both controls to identical pixel height for clean alignment */
  .brand-mark {
    width: 44px;
    height: 44px;
    flex-shrink: 0;
    box-sizing: border-box;
  }
  .tabs {
    height: 44px;
    padding: 4px;
    box-sizing: border-box;
    align-items: stretch;
  }
  /* Tabs height was being broken by .tab's vertical padding; let flex stretch handle it instead */
  .tab {
    padding: 0 14px;
    display: inline-flex;
    align-items: center;
    line-height: 1;
  }
  .brand-text {
    display: none;
  }
  .github-link {
    display: none;
  }
  .tabs {
    margin-top: 0;
    flex-shrink: 0;
  }
  .card {
    padding: 18px;
  }
  h2 {
    font-size: 1.25rem;
  }
  h3 {
    font-size: 1.02rem;
  }
  p.lead {
    font-size: 0.98rem;
  }
  /* (alignment-related .tabs / .tab rules consolidated above; only keep type tweak here) */
  .tab {
    font-size: 0.88rem;
  }
  .subtab {
    padding: 6px 10px;
    font-size: 0.82rem;
  }
  .apps-grid {
    grid-template-columns: 1fr;
  }
  .chart-wrap {
    height: 320px;
  }
  .step-body,
  .piece-card {
    padding: 14px;
  }
  .step-line,
  .piece-eq {
    font-size: 0.88rem;
  }
  /* Tighter top action row on mobile */
  .actions-row {
    gap: 6px;
  }
  .actions-row .icon-btn {
    width: 40px;
    padding: 0 10px;
  }
  .actions-hint {
    font-size: 0.76rem;
  }
  /* Predict card: keep equations scrollable, slightly smaller */
  .predict-eq {
    font-size: 0.74rem;
  }
  .predict-result {
    flex-wrap: wrap;
    gap: 4px;
  }
  /* Sidebar boundary: keep header readable when sticky */
  .site-header {
    padding: 14px 0;
  }
  .brand-text h1 {
    font-size: 1rem;
  }
}
@media (max-width: 380px) {
  .container {
    padding: 0 12px;
  }
  .card {
    padding: 14px;
  }
  .brand-text h1 {
    font-size: 0.98rem;
  }
  .brand-text p {
    font-size: 0.76rem;
  }
  .github-link {
    display: none;
  }
  .tab {
    padding: 8px 12px;
    font-size: 0.84rem;
  }
}

/* Utility */
.hidden {
  display: none !important;
}
)------"

APP_CLIENT_JS <- r"------(
/* =============================================================
   Cubic Spline Interpolation, Shiny client
   Same UI as the static version. R does the math; this file
   handles DOM, tabs, points table, Chart.js, and Shiny I/O.
   ============================================================= */

// ---------- DOM helpers ----------
const $ = (id) => document.getElementById(id);
const fmt = (v, p = 4) => {
  if (!isFinite(v)) return String(v);
  if (v === 0) return "0";
  const abs = Math.abs(v);
  if (abs < 1e-4 || abs >= 1e6) return v.toExponential(4);
  return Number(v.toFixed(p)).toString();
};

// ---------- Default & preset data (same as static version) ----------
const DEFAULT_POINTS = [
  { x: 0, y: 1 },
  { x: 1, y: 0.540302 },
  { x: 2, y: -0.416147 },
  { x: 3, y: -0.989992 },
  { x: 4, y: -0.653644 },
];

const round6 = (v) => Number(v.toFixed(6));
const PRESETS = {
  runge: [-1, -0.5, 0, 0.5, 1].map((x) => ({
    x,
    y: round6(1 / (1 + 25 * x * x)),
  })),
  sine: [0, 1, 2, 3, 4, 5, 6].map((x) => ({ x, y: round6(Math.sin(x)) })),
  textbook: [
    { x: 0, y: 1 },
    { x: 1, y: round6(Math.E) },
    { x: 2, y: round6(Math.E ** 2) },
    { x: 3, y: round6(Math.E ** 3) },
  ],
  temperature: [
    { x: 0, y: 22 },
    { x: 4, y: 19 },
    { x: 8, y: 24 },
    { x: 12, y: 30 },
    { x: 16, y: 32 },
    { x: 20, y: 27 },
    { x: 24, y: 23 },
  ],
};

let points = DEFAULT_POINTS.map((p) => ({ ...p }));
let chart = null;

// ---------- Tab switching ----------
function switchTab(name) {
  document.querySelectorAll(".tab").forEach((t) => {
    const active = t.dataset.tab === name;
    t.classList.toggle("is-active", active);
    t.setAttribute("aria-selected", active ? "true" : "false");
  });
  document.querySelectorAll(".panel").forEach((p) => {
    p.classList.toggle("is-active", p.id === name);
  });
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function switchSubtab(name) {
  document.querySelectorAll(".subtab").forEach((t) => {
    const active = t.dataset.subtab === name;
    t.classList.toggle("is-active", active);
    t.setAttribute("aria-selected", active ? "true" : "false");
  });
  document.querySelectorAll(".subpanel").forEach((p) => {
    p.classList.toggle("is-active", p.id === name);
  });
  if (chart) chart.resize();
}

// ---------- Points table ----------
function renderPoints() {
  const tbody = $("points-tbody");
  if (!tbody) return;
  tbody.innerHTML = "";
  points.forEach((p, i) => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${i}</td>
      <td><input type="number" step="any" data-i="${i}" data-k="x" value="${p.x}"></td>
      <td><input type="number" step="any" data-i="${i}" data-k="y" value="${p.y}"></td>
      <td><button class="row-del" data-del="${i}" aria-label="Remove row ${i}">×</button></td>
    `;
    tbody.appendChild(tr);
  });
  tbody.querySelectorAll("input").forEach((inp) => {
    inp.addEventListener("input", (e) => {
      const i = +e.target.dataset.i;
      const k = e.target.dataset.k;
      const v = parseFloat(e.target.value);
      if (!Number.isNaN(v)) points[i][k] = v;
    });
  });
  tbody.querySelectorAll(".row-del").forEach((btn) => {
    btn.addEventListener("click", () => {
      const i = +btn.dataset.del;
      if (points.length <= 3) {
        showError("Cubic spline needs at least 3 points.");
        return;
      }
      points.splice(i, 1);
      renderPoints();
    });
  });
}

function showError(msg) {
  const el = $("error-text");
  if (el) el.textContent = msg || "";
}

// ---------- Chart (same as static version) ----------
function buildChart(spline, evalPoint) {
  const dataPoints = spline.points;
  const curve = spline.curve;

  const ACCENT = "#818cf8";
  const POINT = "#fafafa";
  const EVAL = "#34d399";
  const TEXT = "#fafafa";
  const MUTED = "#a1a1aa";
  const GRID = "rgba(255, 255, 255, 0.06)";

  const datasets = [
    {
      label: "Cubic spline S(x)",
      data: curve,
      borderColor: ACCENT,
      backgroundColor: "rgba(129,140,248,0.08)",
      borderWidth: 2,
      pointRadius: 0,
      tension: 0,
      fill: false,
      type: "line",
    },
    {
      label: "Data points",
      data: dataPoints,
      backgroundColor: POINT,
      borderColor: POINT,
      pointRadius: 4,
      pointHoverRadius: 6,
      type: "scatter",
      showLine: false,
    },
  ];

  if (evalPoint && evalPoint.y !== null && evalPoint.y !== undefined) {
    datasets.push({
      label: `S(${fmt(evalPoint.x, 4)}) = ${fmt(evalPoint.y, 4)}`,
      data: [evalPoint],
      backgroundColor: EVAL,
      borderColor: EVAL,
      borderWidth: 2,
      pointRadius: 6,
      pointHoverRadius: 8,
      type: "scatter",
      showLine: false,
    });
  }

  // Playhead is drawn entirely on a separate overlay canvas (#playhead-overlay).
  // No datasets are added for it, so Chart.js never refits the layout when
  // playback starts/stops. Plot stays absolutely still during audio.

  const cfg = {
    data: { datasets },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 350 },
      interaction: { mode: "nearest", intersect: false },
      layout: { padding: { top: 8, bottom: 4 } },
      plugins: {
        legend: {
          position: "top",
          align: "center",
          labels: {
            font: { family: "Manrope", size: 12 },
            padding: 22,
            usePointStyle: true,
            color: MUTED,
            filter: (item) => !String(item.text || "").startsWith("__"),
          },
        },
        tooltip: {
          backgroundColor: "#18181b",
          borderColor: "#3f3f46",
          borderWidth: 1,
          titleColor: TEXT,
          bodyColor: TEXT,
          padding: 10,
          filter: (ctx) => !String(ctx.dataset.label || "").startsWith("__"),
          callbacks: {
            label: (ctx) =>
              `(${fmt(ctx.parsed.x, 4)}, ${fmt(ctx.parsed.y, 4)})`,
          },
        },
        title: { display: false },
      },
      scales: {
        x: {
          type: "linear",
          title: {
            display: true,
            text: "x",
            font: { family: "Manrope", size: 12, weight: "500" },
            color: MUTED,
          },
          grid: { color: GRID },
          border: { color: "#3f3f46" },
          ticks: { font: { family: "JetBrains Mono", size: 11 }, color: MUTED },
        },
        y: {
          type: "linear",
          title: {
            display: true,
            text: "y",
            font: { family: "Manrope", size: 12, weight: "500" },
            color: MUTED,
          },
          grid: { color: GRID },
          border: { color: "#3f3f46" },
          ticks: { font: { family: "JetBrains Mono", size: 11 }, color: MUTED },
        },
      },
    },
  };

  if (chart) {
    chart.data = cfg.data;
    chart.options = cfg.options;
    chart.update();
  } else {
    const canvas = $("spline-chart");
    if (canvas) chart = new Chart(canvas, cfg);
  }
}

// ---------- Hear Your Spline (Web Audio wavetable synth) ----------
let lastCurve = null;
let audioCtx = null;
let activeSource = null;

function playMelody() {
  if (!lastCurve || lastCurve.length === 0) return;
  const playBtn = $("play-btn");
  try {
    if (!audioCtx) {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioCtx.state === "suspended") audioCtx.resume();
    if (activeSource) {
      try {
        activeSource.onended = null;
        activeSource.stop();
      } catch (_) {}
      activeSource = null;
    }

    const N = 1024;
    const wavetable = new Float32Array(N);
    for (let i = 0; i < N; i++) {
      const t = (i / N) * 2 * Math.PI;
      wavetable[i] = 0.85 * Math.sin(t) + 0.15 * Math.sin(2 * t);
    }
    const buffer = audioCtx.createBuffer(1, N, audioCtx.sampleRate);
    buffer.copyToChannel(wavetable, 0);
    const source = audioCtx.createBufferSource();
    source.buffer = buffer;
    source.loop = true;

    const M = 200;
    const ys = new Array(M);
    let yMin = Infinity,
      yMax = -Infinity;
    const C = lastCurve.length;
    for (let i = 0; i < M; i++) {
      const idx = Math.min(C - 1, Math.floor((i / M) * C));
      const y = lastCurve[idx].y;
      ys[i] = y;
      if (y < yMin) yMin = y;
      if (y > yMax) yMax = y;
    }
    const yRange = yMax - yMin || 1;
    const minFreq = 110;
    const maxFreq = 440;
    const sampleRate = audioCtx.sampleRate;
    const rates = new Float32Array(M);
    for (let i = 0; i < M; i++) {
      const norm = (ys[i] - yMin) / yRange;
      const freq = minFreq * Math.pow(maxFreq / minFreq, norm);
      rates[i] = (freq * N) / sampleRate;
    }

    const dur = 2.0;
    const t0 = audioCtx.currentTime;
    source.playbackRate.setValueAtTime(rates[0], t0);
    source.playbackRate.setValueCurveAtTime(rates, t0, dur);

    const gain = audioCtx.createGain();
    gain.gain.setValueAtTime(0, t0);
    gain.gain.linearRampToValueAtTime(0.22, t0 + 0.05);
    gain.gain.setValueAtTime(0.22, t0 + dur - 0.15);
    gain.gain.linearRampToValueAtTime(0, t0 + dur);

    source.connect(gain).connect(audioCtx.destination);
    source.start(t0);
    source.stop(t0 + dur + 0.05);

    if (playBtn) playBtn.classList.add("is-playing");
    startPlayhead(lastCurve, dur);
    source.onended = () => {
      if (activeSource === source) activeSource = null;
      if (playBtn) playBtn.classList.remove("is-playing");
      stopPlayhead();
    };
    activeSource = source;
  } catch (e) {
    console.error("playMelody failed", e);
    if (playBtn) playBtn.classList.remove("is-playing");
    showError("Audio playback failed: " + e.message);
  }
}

// ---------- Playhead animation (vertical line + glowing curve point) ----------
let playheadFrame = null;

function evalCurveAt(curve, x) {
  const n = curve.length;
  if (n === 0) return 0;
  if (x <= curve[0].x) return curve[0].y;
  if (x >= curve[n - 1].x) return curve[n - 1].y;
  let lo = 0,
    hi = n - 1;
  while (lo < hi - 1) {
    const mid = (lo + hi) >> 1;
    if (curve[mid].x <= x) lo = mid;
    else hi = mid;
  }
  const a = curve[lo],
    b = curve[hi];
  const t = (x - a.x) / (b.x - a.x);
  return a.y + t * (b.y - a.y);
}

function syncOverlaySize() {
  const main = $("spline-chart");
  const overlay = $("playhead-overlay");
  if (!main || !overlay) return null;
  const w = main.width;
  const h = main.height;
  if (overlay.width !== w) overlay.width = w;
  if (overlay.height !== h) overlay.height = h;
  overlay.style.width = main.style.width || main.clientWidth + "px";
  overlay.style.height = main.style.height || main.clientHeight + "px";
  return overlay;
}

function clearOverlay() {
  const overlay = $("playhead-overlay");
  if (!overlay) return;
  const ctx = overlay.getContext("2d");
  ctx.clearRect(0, 0, overlay.width, overlay.height);
}

function drawPlayheadAt(x, y) {
  if (!chart) return;
  const overlay = syncOverlaySize();
  if (!overlay) return;
  const ctx = overlay.getContext("2d");
  ctx.clearRect(0, 0, overlay.width, overlay.height);

  const dpr = window.devicePixelRatio || 1;
  const xPx = chart.scales.x.getPixelForValue(x) * dpr;
  const yPx = chart.scales.y.getPixelForValue(y) * dpr;
  const top = chart.chartArea.top * dpr;
  const bottom = chart.chartArea.bottom * dpr;

  ctx.save();
  // Vertical dashed line
  ctx.beginPath();
  ctx.setLineDash([5 * dpr, 4 * dpr]);
  ctx.strokeStyle = "#f472b6";
  ctx.lineWidth = 1.5 * dpr;
  ctx.moveTo(xPx, top);
  ctx.lineTo(xPx, bottom);
  ctx.stroke();

  // Halo
  ctx.setLineDash([]);
  ctx.beginPath();
  ctx.arc(xPx, yPx, 14 * dpr, 0, 2 * Math.PI);
  ctx.fillStyle = "rgba(244,114,182,0.25)";
  ctx.fill();

  // Outer ring
  ctx.beginPath();
  ctx.arc(xPx, yPx, 6 * dpr, 0, 2 * Math.PI);
  ctx.fillStyle = "rgba(244,114,182,0.45)";
  ctx.fill();

  // Inner bright dot
  ctx.beginPath();
  ctx.arc(xPx, yPx, 4 * dpr, 0, 2 * Math.PI);
  ctx.fillStyle = "#f472b6";
  ctx.fill();
  ctx.restore();
}

function startPlayhead(curve, durSec) {
  if (!chart || !curve || curve.length === 0) return;
  const x0 = curve[0].x;
  const xn = curve[curve.length - 1].x;

  const startMs = performance.now();
  if (playheadFrame) cancelAnimationFrame(playheadFrame);

  function tick(now) {
    const t = (now - startMs) / 1000;
    if (t >= durSec) {
      stopPlayhead();
      return;
    }
    const frac = t / durSec;
    const x = x0 + (xn - x0) * frac;
    const y = evalCurveAt(curve, x);
    drawPlayheadAt(x, y);
    playheadFrame = requestAnimationFrame(tick);
  }
  playheadFrame = requestAnimationFrame(tick);
}

function stopPlayhead() {
  if (playheadFrame) {
    cancelAnimationFrame(playheadFrame);
    playheadFrame = null;
  }
  clearOverlay();
}

function stopMelody() {
  if (activeSource) {
    try {
      activeSource.onended = null;
      activeSource.stop();
    } catch (_) {}
    activeSource = null;
  }
  const playBtn = $("play-btn");
  if (playBtn) playBtn.classList.remove("is-playing");
  stopPlayhead();
}

// ---------- Trigger compute via Shiny ----------
function compute() {
  if (!window.Shiny || !window.Shiny.setInputValue) return;
  const evalRaw = $("eval-x") ? $("eval-x").value : "";
  const payload = {
    points: points.slice(),
    type: $("boundary") ? $("boundary").value : "natural",
    fp0:
      $("fp-start") && $("fp-start").value !== ""
        ? parseFloat($("fp-start").value)
        : 0,
    fpn:
      $("fp-end") && $("fp-end").value !== ""
        ? parseFloat($("fp-end").value)
        : 0,
    evalX: evalRaw === "" ? null : parseFloat(evalRaw),
    nonce: Date.now(),
  };
  Shiny.setInputValue("compute_request", payload, { priority: "event" });
}

// ---------- Wire up controls ----------
function initControls() {
  document.querySelectorAll(".tab").forEach((btn) => {
    btn.addEventListener("click", () => switchTab(btn.dataset.tab));
  });
  document.querySelectorAll(".subtab").forEach((btn) => {
    btn.addEventListener("click", () => switchSubtab(btn.dataset.subtab));
  });
  const goto = $("goto-calc-btn");
  if (goto) goto.addEventListener("click", () => switchTab("calc"));

  const addBtn = $("add-row-btn");
  if (addBtn)
    addBtn.addEventListener("click", () => {
      const last = points[points.length - 1] || { x: 0, y: 0 };
      points.push({ x: last.x + 1, y: 0 });
      renderPoints();
    });
  const resetBtn = $("reset-points-btn");
  if (resetBtn)
    resetBtn.addEventListener("click", () => {
      points = DEFAULT_POINTS.map((p) => ({ ...p }));
      renderPoints();
      const presetEl = $("preset");
      if (presetEl) presetEl.value = "";
    });
  const presetEl = $("preset");
  if (presetEl)
    presetEl.addEventListener("change", (e) => {
      const key = e.target.value;
      if (PRESETS[key]) {
        points = PRESETS[key].map((p) => ({ ...p }));
        renderPoints();
      }
    });
  const boundaryEl = $("boundary");
  if (boundaryEl)
    boundaryEl.addEventListener("change", (e) => {
      $("clamped-fields").classList.toggle(
        "hidden",
        e.target.value !== "clamped",
      );
    });
  const calcBtn = $("calc-btn");
  if (calcBtn) calcBtn.addEventListener("click", compute);
  const evalX = $("eval-x");
  if (evalX)
    evalX.addEventListener("input", () => {
      if (chart) compute();
    });
  const playBtn = $("play-btn");
  if (playBtn) {
    playBtn.addEventListener("click", () => {
      if (playBtn.classList.contains("is-playing")) stopMelody();
      else playMelody();
    });
  }
}

// ---------- Shiny message handlers ----------
function initShinyHandlers() {
  if (!window.Shiny) return;

  Shiny.addCustomMessageHandler("spline_result", function (payload) {
    if (payload.error) {
      showError(payload.error);
      return;
    }
    showError("");
    buildChart(payload, payload.evalPoint);
    lastCurve = payload.curve || null;
    const playBtn = $("play-btn");
    if (playBtn && lastCurve && lastCurve.length > 0) playBtn.disabled = false;
  });

  function setHtmlAndTypeset(elId, html) {
    const el = $(elId);
    if (!el) return;
    el.innerHTML = html || "";
    if (window.MathJax && MathJax.typesetPromise) {
      MathJax.typesetPromise([el]).catch(function () {});
    }
  }

  Shiny.addCustomMessageHandler("steps_html", function (p) {
    setHtmlAndTypeset("steps-output", p.html);
  });
  Shiny.addCustomMessageHandler("coef_html", function (p) {
    setHtmlAndTypeset("coef-output", p.html);
  });
  Shiny.addCustomMessageHandler("pieces_html", function (p) {
    setHtmlAndTypeset("pieces-output", p.html);
  });
  Shiny.addCustomMessageHandler("predict_html", function (p) {
    setHtmlAndTypeset("predict-output", p.html);
  });

  // Initial compute: multi-path trigger so it fires regardless of when
  // Shiny's session events land relative to this script.
  let initialComputeDone = false;
  function triggerInitialCompute() {
    if (initialComputeDone) return;
    if (
      window.Shiny &&
      Shiny.setInputValue &&
      Shiny.shinyapp &&
      Shiny.shinyapp.isConnected &&
      Shiny.shinyapp.isConnected()
    ) {
      initialComputeDone = true;
      compute();
    }
  }
  document.addEventListener("shiny:connected", triggerInitialCompute);
  document.addEventListener("shiny:sessioninitialized", triggerInitialCompute);
  document.addEventListener("shiny:idle", triggerInitialCompute);
  // Fallback poll, in case all three events landed before our listeners.
  let pollTries = 0;
  const pollId = setInterval(function () {
    pollTries++;
    triggerInitialCompute();
    if (initialComputeDone || pollTries > 40) clearInterval(pollId);
  }, 100);
}

// ---------- Init ----------
function init() {
  renderPoints();
  initControls();
  initShinyHandlers();
  const yearEl = $("year");
  if (yearEl) yearEl.textContent = new Date().getFullYear();
}

if (document.readyState !== "loading") {
  init();
} else {
  document.addEventListener("DOMContentLoaded", init);
}
)------"




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
      "A <strong>cubic spline</strong> is a piecewise cubic polynomial that passes through a given set of data points and is <em>smooth</em> at every interior point: value, slope, and curvature all match across adjacent pieces."
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
          tags$p("Designing aerodynamic shapes (wings, hulls, car bodies) from sparse points.")),
      div(class = "app-card", tags$h4("Data Science"),
          tags$p("Smooth missing-value imputation, monotone calibration curves, and signal resampling."))
    ),
    tags$h3("Conclusion"),
    tags$p(HTML(
      "Cubic spline interpolation is a clean answer to a hard problem: how to draw a smooth curve",
      "through data without the explosive oscillations that plague high-degree polynomials.",
      "By insisting on <strong>low-degree pieces</strong> (cubic on each interval) joined under",
      "<strong>$C^2$ continuity</strong>, the method trades a single global formula for a system",
      "that is both <em>visually faithful</em> and <em>numerically stable</em>, and the",
      "tridiagonal solve makes it cheap enough to run in real time on millions of points."
    )),
    tags$p(HTML(
      "The wider implication is methodological. Many problems in numerical analysis (root-finding,",
      "integration, ODE solving) share the same lesson: a globally-defined object often misbehaves,",
      "while a <strong>piecewise-local construction with smoothness conditions</strong> stays well-conditioned.",
      "Cubic splines made this idea concrete in interpolation; the same pattern reappears in finite-element",
      "methods, signal processing kernels, and modern machine-learning techniques (e.g., natural cubic",
      "splines as regression smoothers, monotone splines for calibration). Learning splines, then, isn't",
      "just learning interpolation. It's a first encounter with one of the most productive ideas",
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
      tags$button(class = "btn btn-primary btn-block", id = "calc-btn",
                  type = "button", "Compute Spline"),
      tags$p(class = "actions-hint",
        HTML("Use <strong>Play</strong> on the plot to hear the curve as a melody, where height becomes pitch.")
      ),
      tags$p(class = "error-text", id = "error-text", role = "alert"),
      div(class = "field",
        tags$label(`for` = "preset", "Quick presets"),
        tags$select(id = "preset",
          tags$option(value = "", HTML("Choose a preset&hellip;")),
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
          div(class = "chart-wrap",
            tags$canvas(id = "spline-chart"),
            tags$canvas(id = "playhead-overlay", `aria-hidden` = "true"),
            HTML('<span class="info-tooltip" tabindex="0" aria-label="What\'s shown here"><svg class="info-glyph" viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"><circle cx="8" cy="8" r="7" fill="none" stroke="currentColor" stroke-width="1.4"/><circle cx="8" cy="4.5" r="0.9" fill="currentColor"/><path d="M8 7v5" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/></svg><span class="info-content" role="tooltip">The indigo curve is the cubic spline interpolant; white dots are the input data points. If you provided an evaluation \\(x\\), the green marker shows \\(S(x)\\) on the spline.</span></span>')
          ),
          div(class = "plot-controls",
            tags$button(class = "plot-play-btn", id = "play-btn",
                        type = "button", disabled = NA, `aria-label` = "Play melody",
              HTML('<svg class="play-glyph play-icon" viewBox="0 0 16 16" width="18" height="18" aria-hidden="true"><path d="M13 2v8.2a2.4 2.4 0 1 1-1.2-2.05V4.2L7 5.4v6.4a2.4 2.4 0 1 1-1.2-2.05V3.4L13 2z" fill="currentColor"/></svg><svg class="play-glyph stop-icon" viewBox="0 0 16 16" width="14" height="14" aria-hidden="true"><rect x="2" y="2" width="12" height="12" rx="2" fill="currentColor"/></svg>')
            )
          )
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

    tags$style(HTML(APP_CSS)),

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
    tags$script(`async` = NA, src = "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"),
    tags$script(src = "https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js")
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
    tags$script(HTML(APP_CLIENT_JS))
  )
)

# === HTML builders for Steps / Coefficients / Piecewise ===
# Build as plain HTML strings, pushed to the client via custom messages
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
  tex <- function(v) HTML(sprintf("\\(%s\\)", v))
  rows <- lapply(seq_len(n), function(i) {
    tags$tr(
      tags$td(tex(i - 1)),
      tags$td(tex(fmt(s$xs[i]))),
      tags$td(tex(fmt(s$xs[i + 1]))),
      tags$td(tex(fmt(s$a[i]))),
      tags$td(tex(fmt(s$b[i]))),
      tags$td(tex(fmt(s$c[i]))),
      tags$td(tex(fmt(s$d[i])))
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
