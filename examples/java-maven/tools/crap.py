#!/usr/bin/env python3
"""
CRAP (Change Risk Anti-Patterns) gate.

    CRAP(m) = complexity(m)^2 * (1 - coverage(m))^3 + complexity(m)

Punishes the *combination* of complex and untested. Simple code may be lightly
tested; gnarly code must be covered or the number explodes.

Reads a JaCoCo XML report. Deterministic: exits 1 if any method is over the threshold.
No model judgment involved.

Usage:
    tools/crap.py <jacoco.xml> [--threshold N] [--package-prefix com.example]

Other ecosystems: this needs per-method cyclomatic complexity *and* per-method coverage in
one report, which JaCoCo gives you for free. Elsewhere you join two tools — e.g. `radon cc
--json` with `coverage json` for Python, or `eslint complexity` with `nyc` for JS. See
docs/GATES.md.
"""
import math
import os
import sys
import xml.etree.ElementTree as ET

DEFAULT_THRESHOLD = 30.0


def counter(node, kind):
    for c in node.findall("counter"):
        if c.get("type") == kind:
            return int(c.get("missed")), int(c.get("covered"))
    return 0, 0


def crap(complexity, coverage):
    return complexity ** 2 * (1 - coverage) ** 3 + complexity


def coverage_needed(complexity, threshold):
    """Coverage that would bring this method under the threshold at its current complexity.

    CRAP = c^2 (1-v)^3 + c = T   ->   v = 1 - cbrt((T - c) / c^2)
    Returns None when no amount of coverage is enough, which happens once complexity alone
    exceeds the threshold.
    """
    if complexity >= threshold:
        return None
    return 1 - ((threshold - complexity) / complexity ** 2) ** (1 / 3)


def complexity_needed(coverage, threshold):
    """Complexity that would bring this method under the threshold at its current coverage.

    a c^2 + c - T = 0 with a = (1-v)^3   ->   c = (-1 + sqrt(1 + 4aT)) / 2a
    """
    a = (1 - coverage) ** 3
    if a <= 0:
        return threshold
    return (-1 + math.sqrt(1 + 4 * a * threshold)) / (2 * a)


def advice(complexity, coverage, threshold):
    """What this method actually needs. Two levers; say where each one lands."""
    options = []

    v = coverage_needed(complexity, threshold)
    if v is not None:
        pct = math.ceil(v * 100)
        if pct > math.floor(coverage * 100):
            options.append(f"cover {pct}% of its lines (now {coverage * 100:.0f}%)")

    c = math.floor(complexity_needed(coverage, threshold))
    if c >= 1 and c < complexity:
        options.append(f"reduce complexity to {c} (now {complexity})")

    if not options:
        return "split this method — neither lever alone gets it under the threshold"
    return "either " + ", or ".join(options) if len(options) > 1 else options[0]


def main(argv):
    path = os.environ.get("CRAP_REPORT", "target/site/jacoco/jacoco.xml")
    threshold = float(os.environ.get("CRAP_THRESHOLD", DEFAULT_THRESHOLD))
    prefix = os.environ.get("CRAP_PACKAGE_PREFIX", "")

    args = argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--threshold":
            threshold = float(args[i + 1]); i += 2
        elif args[i] == "--package-prefix":
            prefix = args[i + 1]; i += 2
        else:
            path = args[i]; i += 1

    try:
        root = ET.parse(path).getroot()
    except FileNotFoundError:
        print(f"CRAP: no coverage report at {path} — generate it before this gate runs.")
        return 1

    if root.tag != "report":
        print(f"CRAP: {path} is not a JaCoCo XML report (root element is <{root.tag}>).")
        return 1

    rows = []
    for pkg in root.findall("package"):
        if not pkg.get("name", "").replace("/", ".").startswith(prefix):
            continue
        for cls in pkg.findall("class"):
            cls_name = cls.get("name").replace("/", ".")
            for m in cls.findall("method"):
                miss_c, cov_c = counter(m, "COMPLEXITY")
                complexity = miss_c + cov_c
                miss_l, cov_l = counter(m, "LINE")
                total_l = miss_l + cov_l
                coverage = (cov_l / total_l) if total_l else 1.0
                if complexity == 0:
                    continue
                rows.append((crap(complexity, coverage), cls_name, m.get("name"),
                             complexity, coverage))

    if not rows:
        where = f" under package prefix '{prefix}'" if prefix else ""
        print(f"CRAP: no methods found{where} in {path}.")
        return 1

    rows.sort(reverse=True)
    width = max(len(f"{c}.{n}") for _, c, n, _, _ in rows) + 2
    print(f"  {'METHOD'.ljust(width)}{'CPLX':>6}{'COV':>8}{'CRAP':>9}")
    failed = []
    for score, cls_name, method, complexity, coverage in rows:
        flag = "  FAIL" if score > threshold else ""
        if flag:
            failed.append((cls_name, method, complexity, coverage, score))
        print(f"  {(cls_name + '.' + method).ljust(width)}{complexity:>6}"
              f"{coverage * 100:>7.0f}%{score:>9.2f}{flag}")

    print()
    if failed:
        print(f"CRAP FAILED: {len(failed)} method(s) above threshold {threshold:g}.")
        print()
        print("  CRAP = complexity^2 x (1 - coverage)^3 + complexity, so there are two")
        print("  levers: make the method simpler, or test more of it. Per method:")
        print()
        for cls_name, method, complexity, coverage, score in failed:
            print(f"  {cls_name}.{method}  ({score:.2f})")
            print(f"      {advice(complexity, coverage, threshold)}")
        print()
        print("  Extracting a method splits its complexity across two methods and usually")
        print("  drops both under the line. Raising coverage without simplifying works too,")
        print("  but leaves the complexity for the next person.")
        return 1
    print(f"CRAP OK: {len(rows)} method(s), all at or below threshold {threshold:g}.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
