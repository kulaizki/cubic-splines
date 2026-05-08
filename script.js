/* =============================================================
   Cubic Spline Interpolation, pure JS
   Implements natural and clamped cubic splines via the
   tridiagonal (Thomas) algorithm following Burden & Faires.
   ============================================================= */

// ---------- DOM helpers ----------
const $ = (id) => document.getElementById(id);
const fmt = (v, p = 6) => {
  if (!isFinite(v)) return String(v);
  if (v === 0) return "0";
  const abs = Math.abs(v);
  if (abs < 1e-4 || abs >= 1e6) return v.toExponential(4);
  return Number(v.toFixed(p)).toString();
};
const typeset = (els) => {
  if (window.MathJax && window.MathJax.typesetPromise) {
    return window.MathJax.typesetPromise(els);
  }
  return Promise.resolve();
};

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

document.querySelectorAll(".tab").forEach((btn) => {
  btn.addEventListener("click", () => switchTab(btn.dataset.tab));
});
$("goto-calc-btn").addEventListener("click", () => switchTab("calc"));

document.querySelectorAll(".subtab").forEach((btn) => {
  btn.addEventListener("click", () => {
    const name = btn.dataset.subtab;
    document.querySelectorAll(".subtab").forEach((t) => {
      const active = t.dataset.subtab === name;
      t.classList.toggle("is-active", active);
      t.setAttribute("aria-selected", active ? "true" : "false");
    });
    document.querySelectorAll(".subpanel").forEach((p) => {
      p.classList.toggle("is-active", p.id === name);
    });
    if (chart) chart.resize();
  });
});

// ---------- Default & preset data ----------
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

// ---------- Points table ----------
let points = DEFAULT_POINTS.map((p) => ({ ...p }));

function renderPoints() {
  const tbody = $("points-tbody");
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

$("add-row-btn").addEventListener("click", () => {
  const last = points[points.length - 1] || { x: 0, y: 0 };
  points.push({ x: last.x + 1, y: 0 });
  renderPoints();
});
$("reset-points-btn").addEventListener("click", () => {
  points = DEFAULT_POINTS.map((p) => ({ ...p }));
  renderPoints();
  $("preset").value = "";
});
$("preset").addEventListener("change", (e) => {
  const key = e.target.value;
  if (PRESETS[key]) {
    points = PRESETS[key].map((p) => ({ ...p }));
    renderPoints();
  }
});
$("boundary").addEventListener("change", (e) => {
  $("clamped-fields").classList.toggle("hidden", e.target.value !== "clamped");
});

function showError(msg) {
  $("error-text").textContent = msg || "";
}

// ---------- Cubic spline algorithm ----------
/**
 * Compute the cubic spline coefficients for n+1 points.
 * Each segment is S_i(x) = a_i + b_i*(x-x_i) + c_i*(x-x_i)^2 + d_i*(x-x_i)^3
 * for i = 0..n-1 on [x_i, x_{i+1}]. Burden & Faires §3.5.
 */
function cubicSpline(xs, ys, type = "natural", fp0 = 0, fpn = 0) {
  const n = xs.length - 1;
  const h = new Array(n);
  for (let i = 0; i < n; i++) h[i] = xs[i + 1] - xs[i];

  const alpha = new Array(n + 1).fill(0);
  if (type === "clamped") {
    alpha[0] = (3 * (ys[1] - ys[0])) / h[0] - 3 * fp0;
    alpha[n] = 3 * fpn - (3 * (ys[n] - ys[n - 1])) / h[n - 1];
  }
  for (let i = 1; i < n; i++) {
    alpha[i] =
      (3 * (ys[i + 1] - ys[i])) / h[i] - (3 * (ys[i] - ys[i - 1])) / h[i - 1];
  }

  const l = new Array(n + 1).fill(0);
  const mu = new Array(n + 1).fill(0);
  const z = new Array(n + 1).fill(0);

  if (type === "natural") {
    l[0] = 1;
    mu[0] = 0;
    z[0] = 0;
  } else {
    l[0] = 2 * h[0];
    mu[0] = 0.5;
    z[0] = alpha[0] / l[0];
  }
  for (let i = 1; i < n; i++) {
    l[i] = 2 * (xs[i + 1] - xs[i - 1]) - h[i - 1] * mu[i - 1];
    mu[i] = h[i] / l[i];
    z[i] = (alpha[i] - h[i - 1] * z[i - 1]) / l[i];
  }

  const c = new Array(n + 1).fill(0);
  const b = new Array(n).fill(0);
  const d = new Array(n).fill(0);
  const a = ys.slice(0, n + 1);

  if (type === "natural") {
    l[n] = 1;
    z[n] = 0;
    c[n] = 0;
  } else {
    l[n] = h[n - 1] * (2 - mu[n - 1]);
    z[n] = (alpha[n] - h[n - 1] * z[n - 1]) / l[n];
    c[n] = z[n];
  }
  for (let j = n - 1; j >= 0; j--) {
    c[j] = z[j] - mu[j] * c[j + 1];
    b[j] = (ys[j + 1] - ys[j]) / h[j] - (h[j] * (c[j + 1] + 2 * c[j])) / 3;
    d[j] = (c[j + 1] - c[j]) / (3 * h[j]);
  }

  return {
    type,
    xs,
    ys,
    a: a.slice(0, n),
    b,
    c: c.slice(0, n),
    d,
    h,
    trace: { alpha, l, mu, z, cFull: c },
  };
}

function evalSpline(spline, x) {
  const { a, b, c, d, xs } = spline;
  const n = a.length;
  if (x < xs[0] || x > xs[n]) return null;
  let i = 0;
  for (i = 0; i < n; i++) if (x <= xs[i + 1]) break;
  if (i >= n) i = n - 1;
  const dx = x - xs[i];
  return a[i] + b[i] * dx + c[i] * dx * dx + d[i] * dx * dx * dx;
}

function validatePoints(pts) {
  if (pts.length < 3) return "Cubic spline needs at least 3 points.";
  for (const p of pts) {
    if (!Number.isFinite(p.x) || !Number.isFinite(p.y))
      return "All x and y values must be valid numbers.";
  }
  const sorted = [...pts].sort((a, b) => a.x - b.x);
  for (let i = 1; i < sorted.length; i++) {
    if (sorted[i].x === sorted[i - 1].x)
      return `Duplicate x value: ${sorted[i].x}.`;
  }
  return null;
}

// ---------- Chart ----------
let chart = null;

function buildChart(spline, evalPoint) {
  const { xs } = spline;
  const x0 = xs[0],
    xn = xs[xs.length - 1];
  const N = 400;
  const curve = [];
  for (let k = 0; k <= N; k++) {
    const x = x0 + (xn - x0) * (k / N);
    curve.push({ x, y: evalSpline(spline, x) });
  }
  const dataPoints = spline.xs.map((x, i) => ({ x, y: spline.ys[i] }));

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

  if (evalPoint && evalPoint.y !== null) {
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

  // Playhead is drawn ENTIRELY on a separate overlay canvas (#playhead-overlay).
  // No datasets are added for it, so Chart.js never refits the layout when
  // playback starts/stops. This keeps the plot absolutely still during audio.

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
    chart = new Chart($("spline-chart"), cfg);
  }
}

// ---------- Steps rendering (LaTeX) ----------
function renderSteps(spline) {
  const out = $("steps-output");
  const { xs, h, a, b, c, d, trace, type } = spline;
  const n = xs.length - 1;

  const blocks = [];

  blocks.push({
    num: 1,
    title: "Compute interval widths",
    intro: `\\(h_i = x_{i+1} - x_i\\)`,
    lines: h.map(
      (hi, i) =>
        `\\(h_{${i}} = ${fmt(xs[i + 1])} - ${fmt(xs[i])} = ${fmt(hi)}\\)`,
    ),
  });

  blocks.push({
    num: 2,
    title: "Set the constant terms",
    intro: `\\(a_i = y_i\\)`,
    lines: a.map((ai, i) => `\\(a_{${i}} = ${fmt(ai)}\\)`),
  });

  const alphaLines = [];
  if (type === "clamped") {
    alphaLines.push(
      `\\(\\alpha_{0} = \\dfrac{3(y_1 - y_0)}{h_0} - 3 f'(x_0) = ${fmt(trace.alpha[0])}\\)`,
    );
    alphaLines.push(
      `\\(\\alpha_{${n}} = 3 f'(x_n) - \\dfrac{3(y_n - y_{n-1})}{h_{n-1}} = ${fmt(trace.alpha[n])}\\)`,
    );
  }
  for (let i = 1; i < n; i++) {
    alphaLines.push(
      `\\(\\alpha_{${i}} = \\dfrac{3(y_{${i + 1}} - y_{${i}})}{h_{${i}}} - \\dfrac{3(y_{${i}} - y_{${i - 1}})}{h_{${i - 1}}} = ${fmt(trace.alpha[i])}\\)`,
    );
  }
  blocks.push({
    num: 3,
    title: "Build the right-hand side",
    intro: `Tridiagonal system: \\(h_{i-1}c_{i-1} + 2(h_{i-1}+h_i)c_i + h_i c_{i+1} = \\alpha_i\\)`,
    lines: alphaLines,
  });

  const sweepLines = [];
  for (let i = 0; i <= n; i++) {
    sweepLines.push(
      `\\(i = ${i}: \\quad l_{${i}} = ${fmt(trace.l[i])}, \\;\\; \\mu_{${i}} = ${fmt(trace.mu[i])}, \\;\\; z_{${i}} = ${fmt(trace.z[i])}\\)`,
    );
  }
  blocks.push({
    num: 4,
    title: "Forward sweep (Thomas algorithm)",
    intro: `Solve the tridiagonal system using LU decomposition.`,
    lines: sweepLines,
  });

  blocks.push({
    num: 5,
    title: "Back-substitute for cᵢ",
    intro: `\\(c_i = z_i - \\mu_i \\, c_{i+1}\\)`,
    lines: trace.cFull.map((ci, i) => `\\(c_{${i}} = ${fmt(ci)}\\)`),
  });

  const bdLines = [];
  for (let i = 0; i < n; i++) {
    bdLines.push(
      `\\(b_{${i}} = \\dfrac{y_{${i + 1}} - y_{${i}}}{h_{${i}}} - \\dfrac{h_{${i}}(c_{${i + 1}} + 2 c_{${i}})}{3} = ${fmt(b[i])}\\)`,
    );
    bdLines.push(
      `\\(d_{${i}} = \\dfrac{c_{${i + 1}} - c_{${i}}}{3 h_{${i}}} = ${fmt(d[i])}\\)`,
    );
  }
  blocks.push({
    num: 6,
    title: "Compute the linear and cubic coefficients",
    intro: `\\(b_i = \\dfrac{y_{i+1}-y_i}{h_i} - \\dfrac{h_i(c_{i+1}+2c_i)}{3}\\), \\(\\quad d_i = \\dfrac{c_{i+1}-c_i}{3 h_i}\\)`,
    lines: bdLines,
  });

  out.innerHTML = blocks
    .map(
      (bl) => `
        <div class="step-block">
          <div class="step-header">
            <span class="step-num">${String(bl.num).padStart(2, "0")}</span>
            <span class="step-title">${bl.title}</span>
          </div>
          <div class="step-body">
            <p class="step-intro">${bl.intro}</p>
            ${bl.lines.map((ln) => `<div class="step-line">${ln}</div>`).join("")}
          </div>
        </div>
      `,
    )
    .join("");

  typeset([out]);
}

// ---------- Coefficient table ----------
function renderCoefTable(spline) {
  const { xs, a, b, c, d } = spline;
  const tbody = $("coef-tbody");
  tbody.innerHTML = "";
  const m = (v) => `\\(${v}\\)`;
  for (let i = 0; i < a.length; i++) {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${m(i)}</td>
      <td>${m(fmt(xs[i]))}</td>
      <td>${m(fmt(xs[i + 1]))}</td>
      <td>${m(fmt(a[i]))}</td>
      <td>${m(fmt(b[i]))}</td>
      <td>${m(fmt(c[i]))}</td>
      <td>${m(fmt(d[i]))}</td>
    `;
    tbody.appendChild(tr);
  }
  typeset([tbody]);
}

// ---------- Prediction card (shows which piece + substituted formula) ----------
function renderPredict(spline, x, y) {
  const out = $("predict-output");
  if (!out) return;
  if (spline === null || x === null || !Number.isFinite(x)) {
    out.innerHTML = "";
    return;
  }
  const xs = spline.xs;
  if (y === null) {
    out.innerHTML = `<div class="predict-card predict-out-of-range">x = ${fmt(x)} is outside [${fmt(xs[0])}, ${fmt(xs[xs.length - 1])}]</div>`;
    return;
  }
  const a = spline.a,
    b = spline.b,
    c = spline.c,
    d = spline.d;
  let i = 0;
  for (i = 0; i < a.length; i++) if (x <= xs[i + 1]) break;
  if (i >= a.length) i = a.length - 1;
  const sgn = (v) => (v >= 0 ? "+" : "-");
  const xq = fmt(x, 4);
  const xi = fmt(xs[i]);
  const tex = String.raw`\[
\begin{aligned}
S_{${i}}(${xq}) ={}& ${fmt(a[i])} \\
&${sgn(b[i])}\, ${fmt(Math.abs(b[i]))}\,(${xq} - ${xi}) \\
&${sgn(c[i])}\, ${fmt(Math.abs(c[i]))}\,(${xq} - ${xi})^{2} \\
&${sgn(d[i])}\, ${fmt(Math.abs(d[i]))}\,(${xq} - ${xi})^{3} \\
={}& ${fmt(y, 6)}
\end{aligned}
\]`;
  out.innerHTML = `
    <div class="predict-card">
      <div class="predict-meta">
        Uses piece <span class="predict-piece">\\(S_{${i}}\\)</span>
        on \\([${fmt(xs[i])},\\; ${fmt(xs[i + 1])}]\\)
      </div>
      <div class="predict-eq">${tex}</div>
      <div class="predict-result">
        <span class="predict-label">\\(S(${xq}) =\\)</span>
        <span class="predict-value">${fmt(y, 6)}</span>
      </div>
    </div>
  `;
  typeset([out]);
}

// ---------- Piecewise expressions (LaTeX, multi-line aligned) ----------
function renderPieces(spline) {
  const { xs, a, b, c, d } = spline;
  const out = $("pieces-output");
  const sgn = (v) => (v >= 0 ? "+" : "-");

  const cards = [];
  for (let i = 0; i < a.length; i++) {
    const xi = fmt(xs[i]);
    // Multi-line aligned equation so MathJax wraps cleanly without overflow.
    const tex = String.raw`\[
      \begin{aligned}
      S_{${i}}(x) ={}& ${fmt(a[i])} \\
                     & ${sgn(b[i])}\, ${fmt(Math.abs(b[i]))}\,(x - ${xi}) \\
                     & ${sgn(c[i])}\, ${fmt(Math.abs(c[i]))}\,(x - ${xi})^{2} \\
                     & ${sgn(d[i])}\, ${fmt(Math.abs(d[i]))}\,(x - ${xi})^{3}
      \end{aligned}
    \]`;
    cards.push(`
      <div class="piece-card">
        <div class="piece-header">
          <div class="piece-label">
            <span class="piece-badge">${i + 1}</span>
            <span class="piece-name">Piece</span>
          </div>
          <span class="piece-interval">for \\(x \\in [${fmt(xs[i])},\\; ${fmt(xs[i + 1])}]\\)</span>
        </div>
        <div class="piece-eq">${tex}</div>
      </div>
    `);
  }

  out.innerHTML = cards.join("");
  typeset([out]);
}

// ---------- Main compute ----------
function compute() {
  showError("");
  const sorted = [...points].sort((a, b) => a.x - b.x);
  const err = validatePoints(sorted);
  if (err) {
    showError(err);
    return;
  }

  const xs = sorted.map((p) => p.x);
  const ys = sorted.map((p) => p.y);
  const type = $("boundary").value;
  const fp0 = parseFloat($("fp-start").value) || 0;
  const fpn = parseFloat($("fp-end").value) || 0;

  let spline;
  try {
    spline = cubicSpline(xs, ys, type, fp0, fpn);
  } catch (e) {
    showError("Computation failed: " + e.message);
    return;
  }

  const evalRaw = $("eval-x").value;
  let evalPoint = null;
  if (evalRaw !== "" && Number.isFinite(parseFloat(evalRaw))) {
    const xq = parseFloat(evalRaw);
    const yq = evalSpline(spline, xq);
    if (yq === null) {
      renderPredict(spline, xq, null);
    } else {
      evalPoint = { x: xq, y: yq };
      renderPredict(spline, xq, yq);
    }
  } else {
    renderPredict(null, null, null);
  }

  buildChart(spline, evalPoint);
  renderSteps(spline);
  renderCoefTable(spline);
  renderPieces(spline);
  lastSpline = spline;
  const playBtn = $("play-btn");
  if (playBtn) playBtn.disabled = false;
}

$("calc-btn").addEventListener("click", compute);
$("eval-x").addEventListener("input", () => {
  if (chart) compute();
});

// ---------- Hear Your Spline (Web Audio wavetable synth) ----------
let lastSpline = null;
let audioCtx = null;
let activeSource = null;

function playMelody() {
  if (!lastSpline) return;
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

    // Build a smooth sine-ish wavetable so melody mode sounds clean (1 cycle)
    const N = 1024;
    const wavetable = new Float32Array(N);
    for (let i = 0; i < N; i++) {
      // Mild harmonic mix: sine plus a touch of 2nd harmonic for warmth
      const t = (i / N) * 2 * Math.PI;
      wavetable[i] = 0.85 * Math.sin(t) + 0.15 * Math.sin(2 * t);
    }
    const buffer = audioCtx.createBuffer(1, N, audioCtx.sampleRate);
    buffer.copyToChannel(wavetable, 0);
    const source = audioCtx.createBufferSource();
    source.buffer = buffer;
    source.loop = true;

    // Sample the spline's y over its x range, normalize to [0, 1],
    // map to ~2 octaves around the chosen base pitch.
    const xs = lastSpline.xs;
    const x0 = xs[0],
      xn = xs[xs.length - 1];
    const M = 200;
    const ys = new Array(M);
    let yMin = Infinity,
      yMax = -Infinity;
    for (let i = 0; i < M; i++) {
      const x = x0 + ((xn - x0) * i) / (M - 1);
      const y = evalSpline(lastSpline, x);
      ys[i] = y;
      if (y < yMin) yMin = y;
      if (y > yMax) yMax = y;
    }
    const yRange = yMax - yMin || 1;
    // Pitch span: ~2 octaves centered on A3 (110Hz → 440Hz)
    const minFreq = 110;
    const maxFreq = 440;
    const sampleRate = audioCtx.sampleRate;
    const rates = new Float32Array(M);
    for (let i = 0; i < M; i++) {
      const norm = (ys[i] - yMin) / yRange; // 0..1
      // Exponential mapping (musical perception is logarithmic in pitch)
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
    startPlayhead(lastSpline, dur);
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

// ---------- Playhead animation (overlay canvas, never touches main chart) ----------
let playheadFrame = null;

function syncOverlaySize() {
  const main = $("spline-chart");
  const overlay = $("playhead-overlay");
  if (!main || !overlay) return null;
  // Match the device-pixel size and CSS size of the main canvas
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

  // Convert chart-data coords to canvas pixels using the main chart's scales.
  // Account for devicePixelRatio: Chart.js's getPixelForValue returns CSS pixels,
  // but our overlay's drawing buffer is in device pixels.
  const dpr = window.devicePixelRatio || 1;
  const xPx = chart.scales.x.getPixelForValue(x) * dpr;
  const yPx = chart.scales.y.getPixelForValue(y) * dpr;
  const top = chart.chartArea.top * dpr;
  const bottom = chart.chartArea.bottom * dpr;

  // Vertical dashed line spanning the chart area
  ctx.save();
  ctx.beginPath();
  ctx.setLineDash([5 * dpr, 4 * dpr]);
  ctx.strokeStyle = "#f472b6";
  ctx.lineWidth = 1.5 * dpr;
  ctx.moveTo(xPx, top);
  ctx.lineTo(xPx, bottom);
  ctx.stroke();

  // Soft halo where the line crosses the curve
  ctx.setLineDash([]);
  ctx.beginPath();
  ctx.arc(xPx, yPx, 14 * dpr, 0, 2 * Math.PI);
  ctx.fillStyle = "rgba(244,114,182,0.25)";
  ctx.fill();

  // Outer translucent ring
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

function startPlayhead(spline, durSec) {
  if (!chart) return;
  const xs = spline.xs;
  const x0 = xs[0];
  const xn = xs[xs.length - 1];

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
    const y = evalSpline(spline, x);
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

(function wirePlay() {
  const btn = $("play-btn");
  if (!btn) return;
  btn.addEventListener("click", () => {
    if (btn.classList.contains("is-playing")) stopMelody();
    else playMelody();
  });
})();

// ---------- Init ----------
renderPoints();
$("year").textContent = new Date().getFullYear();
compute();
