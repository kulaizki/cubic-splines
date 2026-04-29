const { cubicSpline, evalSpline } = require("./spline_algo");

const cases = {
  // Burden & Faires Example 1, §3.5 — Natural cubic spline through (0,1),(1,e),(2,e^2),(3,e^3)
  textbook_natural: {
    xs: [0, 1, 2, 3],
    ys: [1, Math.E, Math.E ** 2, Math.E ** 3],
    type: "natural",
  },
  // Burden & Faires Example 2 — Clamped through same points with f'(0)=1, f'(3)=e^3
  textbook_clamped: {
    xs: [0, 1, 2, 3],
    ys: [1, Math.E, Math.E ** 2, Math.E ** 3],
    type: "clamped",
    fp0: 1,
    fpn: Math.E ** 3,
  },
  // sin(x) sampled, natural
  sine_natural: {
    xs: [0, 1, 2, 3, 4, 5, 6],
    ys: [0, 1, 2, 3, 4, 5, 6].map(Math.sin),
    type: "natural",
  },
  // Runge function, natural
  runge_natural: {
    xs: [-1, -0.5, 0, 0.5, 1],
    ys: [-1, -0.5, 0, 0.5, 1].map((x) => 1 / (1 + 25 * x * x)),
    type: "natural",
  },
  // Non-uniform spacing, natural
  nonuniform: {
    xs: [0, 0.3, 1.0, 2.5, 4.0],
    ys: [0, 0.5, 0.7, -0.2, 1.1],
    type: "natural",
  },
};

const out = {};
for (const [name, c] of Object.entries(cases)) {
  const sp = cubicSpline(c.xs, c.ys, c.type, c.fp0 || 0, c.fpn || 0);
  // Sample evaluation points across the domain
  const x0 = c.xs[0],
    xn = c.xs[c.xs.length - 1];
  const samples = [];
  const M = 11;
  for (let k = 0; k < M; k++) {
    const x = x0 + (xn - x0) * (k / (M - 1));
    samples.push([x, evalSpline(sp, x)]);
  }
  out[name] = {
    a: sp.a,
    b: sp.b,
    c: sp.c,
    d: sp.d,
    h: sp.h,
    samples,
  };
}

console.log(JSON.stringify(out));
