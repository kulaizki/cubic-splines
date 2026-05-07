/* =============================================================
   Cubic Spline Interpolation — Shiny client
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

  const cfg = {
    data: { datasets },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 350 },
      interaction: { mode: "nearest", intersect: false },
      plugins: {
        legend: {
          position: "top",
          labels: {
            font: { family: "Manrope", size: 12 },
            padding: 14,
            usePointStyle: true,
            color: MUTED,
          },
        },
        tooltip: {
          backgroundColor: "#18181b",
          borderColor: "#3f3f46",
          borderWidth: 1,
          titleColor: TEXT,
          bodyColor: TEXT,
          padding: 10,
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
    source.onended = () => {
      if (activeSource === source) activeSource = null;
      if (playBtn) playBtn.classList.remove("is-playing");
    };
    activeSource = source;
  } catch (e) {
    console.error("playMelody failed", e);
    if (playBtn) playBtn.classList.remove("is-playing");
    showError("Audio playback failed: " + e.message);
  }
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
  if (playBtn) playBtn.addEventListener("click", playMelody);
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

  // Initial compute — multi-path trigger so it fires regardless of when
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
  // Fallback poll — in case all three events landed before our listeners.
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
