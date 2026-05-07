#!/usr/bin/env python3
"""Verify R cubic_spline implementation (used by app.R) against scipy.

Mirrors verify.py's structure but calls Rscript run_r.R instead of node run_js.js.
"""

import json
import math
import subprocess
import sys
from pathlib import Path

import numpy as np
from scipy.interpolate import CubicSpline

HERE = Path(__file__).parent
r_out = subprocess.check_output(
    ["Rscript", str(HERE / "run_r.R")],
    text=True, cwd=HERE,
)
r = json.loads(r_out)

E = math.e
cases = {
    "textbook_natural": dict(
        xs=[0, 1, 2, 3],
        ys=[1, E, E ** 2, E ** 3],
        bc_type="natural",
    ),
    "textbook_clamped": dict(
        xs=[0, 1, 2, 3],
        ys=[1, E, E ** 2, E ** 3],
        bc_type=((1, 1.0), (1, E ** 3)),
    ),
    "sine_natural": dict(
        xs=[0, 1, 2, 3, 4, 5, 6],
        ys=[math.sin(x) for x in [0, 1, 2, 3, 4, 5, 6]],
        bc_type="natural",
    ),
    "runge_natural": dict(
        xs=[-1, -0.5, 0, 0.5, 1],
        ys=[1 / (1 + 25 * x * x) for x in [-1, -0.5, 0, 0.5, 1]],
        bc_type="natural",
    ),
    "nonuniform": dict(
        xs=[0, 0.3, 1.0, 2.5, 4.0],
        ys=[0, 0.5, 0.7, -0.2, 1.1],
        bc_type="natural",
    ),
}

TOL_COEF = 1e-9
TOL_VAL = 1e-9
all_ok = True
print("=" * 78)
print(f"{'Case':<22} {'max|Δa|':>10} {'max|Δb|':>10} {'max|Δc|':>10} {'max|Δd|':>10} {'max|ΔS|':>10}  result")
print("=" * 78)

for name, c in cases.items():
    cs = CubicSpline(c["xs"], c["ys"], bc_type=c["bc_type"])
    n = len(c["xs"]) - 1
    sp_d = cs.c[0]
    sp_c = cs.c[1]
    sp_b = cs.c[2]
    sp_a = cs.c[3]

    r_case = r[name]

    def as_list(v):
        return [v] if not isinstance(v, list) else v

    r_a = as_list(r_case["a"])
    r_b = as_list(r_case["b"])
    r_c = as_list(r_case["c"])
    r_d = as_list(r_case["d"])

    da = max(abs(r_a[i] - sp_a[i]) for i in range(n))
    db = max(abs(r_b[i] - sp_b[i]) for i in range(n))
    dc = max(abs(r_c[i] - sp_c[i]) for i in range(n))
    dd = max(abs(r_d[i] - sp_d[i]) for i in range(n))

    ds = 0.0
    for sample in r_case["samples"]:
        x, y_r = sample[0], sample[1]
        y_scipy = float(cs(x))
        ds = max(ds, abs(y_r - y_scipy))

    ok = (da < TOL_COEF and db < TOL_COEF and dc < TOL_COEF and dd < TOL_COEF and ds < TOL_VAL)
    all_ok = all_ok and ok
    status = "PASS" if ok else "FAIL"
    print(f"{name:<22} {da:>10.2e} {db:>10.2e} {dc:>10.2e} {dd:>10.2e} {ds:>10.2e}  {status}")

print("=" * 78)
print("OVERALL:", "ALL PASSED ✓" if all_ok else "FAILURES ✗")

# Detailed coefficient comparison for transparency
print("\nDetailed coefficients — textbook_natural (x = 0,1,2,3; y = 1,e,e²,e³)")
cs = CubicSpline([0, 1, 2, 3], [1, E, E ** 2, E ** 3], bc_type="natural")
print(f"  scipy a: {cs.c[3].tolist()}")
print(f"  R     a: {r['textbook_natural']['a']}")
print(f"  scipy b: {cs.c[2].tolist()}")
print(f"  R     b: {r['textbook_natural']['b']}")
print(f"  scipy c: {cs.c[1].tolist()}")
print(f"  R     c: {r['textbook_natural']['c']}")
print(f"  scipy d: {cs.c[0].tolist()}")
print(f"  R     d: {r['textbook_natural']['d']}")

sys.exit(0 if all_ok else 1)
