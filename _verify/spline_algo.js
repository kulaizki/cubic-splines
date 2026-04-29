// Extracted algorithm from script.js (DOM-free) so we can run it in Node.

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

  return { type, xs, ys, a: a.slice(0, n), b, c: c.slice(0, n), d, h };
}

function evalSpline(spline, x) {
  const { a, b, c, d, xs } = spline;
  const n = a.length;
  let i = 0;
  for (i = 0; i < n; i++) if (x <= xs[i + 1]) break;
  if (i >= n) i = n - 1;
  const dx = x - xs[i];
  return a[i] + b[i] * dx + c[i] * dx * dx + d[i] * dx * dx * dx;
}

module.exports = { cubicSpline, evalSpline };
