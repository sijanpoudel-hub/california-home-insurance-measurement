"""Ranking diagnostics for a historical California administrative-count benchmark.

No source counts are replaced. Simulated counts are explicitly labelled draws.
The binomial model is a sensitivity assumption, not a validated sampling model
for these transaction totals. Beta-binomial scenarios are uncalibrated stress
checks for extra variation, not estimates of within-ZIP dependence.
"""
from pathlib import Path
import hashlib
import json
import math
import platform
import sys
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "outputs"
OUT.mkdir(exist_ok=True)
SEED = 20261127
DRAWS = 5000
YEARS = range(2018, 2022)
checks = []


def check(name, value, detail=""):
    checks.append({"check": name, "passed": bool(value), "detail": str(detail)})
    pd.DataFrame(checks).to_csv(OUT / "ranking_checks.csv", index=False)
    if not value:
        raise AssertionError(name + ": " + str(detail))


def save(rows, name):
    pd.DataFrame(rows).to_csv(OUT / ("ranking_" + name + ".csv"),
                              index=False, float_format="%.12g")


def mask(score, fraction=.1):
    a = np.asarray(score, dtype=float)
    if a.ndim != 1 or not len(a) or not np.isfinite(a).all():
        raise ValueError("Scores must be a nonempty finite vector")
    k = math.ceil(fraction * len(a))
    return a >= np.partition(a, len(a)-k)[len(a)-k]


def masks(score, fraction=.1):
    a = np.asarray(score, dtype=float)
    k = math.ceil(fraction * a.shape[1])
    cutoff = np.partition(a, a.shape[1]-k, axis=1)[:, a.shape[1]-k]
    return a >= cutoff[:, None]


def retained(a, b):
    return 100 * np.sum(a & b) / np.sum(a)


d = pd.read_csv(OUT / "extension_matched_input.csv", dtype={"zip": str})
d = d.rename(columns={"new": "N", "renewed": "R", "insurer_nonrenewed": "I",
                      "insured_nonrenewed": "U", "recorded_count_total": "T"})
d["zip"] = d.zip.str.zfill(5)
for c in ["year", "N", "R", "I", "U", "T"]:
    d[c] = pd.to_numeric(d[c], errors="raise")
check("Unique study keys", len(d) == 8503 and not d.duplicated(["zip", "year"]).any())
check("Nonnegative integer counts and exact total", (d[["N", "R", "I", "U", "T"]] >= 0).all().all()
      and np.equal(d[["N", "R", "I", "U", "T"]], np.floor(d[["N", "R", "I", "U", "T"]])).all().all()
      and (d["T"] == d.R + d.I + d.U).all())
source = ROOT / "data_raw" / "California ZIP data for 2015–2021.xlsx"
r = pd.read_excel(source, sheet_name="New Renew NonRenew", dtype={"ZIP Code": str})
r = r.rename(columns={"ZIP Code": "zip", "Year": "year", "New": "N", "Renewed": "R",
                      "Insurer-Initiated Nonrenewed": "I", "Insured-Initiated Nonrenewed": "U"})
r = r[r.year.isin(YEARS)].copy()
r["zip"] = r.zip.str.strip().str.replace(r"\.0$", "", regex=True).str.zfill(5)
j = d.merge(r[["zip", "year", "N", "R", "I", "U"]], on=["zip", "year"],
            how="outer", suffixes=("", "_source"), indicator=True)
check("All source counts independently verified", len(j) == 8503 and (j._merge == "both").all()
      and all((j[c] == j[c+"_source"]).all() for c in ["N", "R", "I", "U"]))
check("Tie inclusion at rank cutoff", mask([.9, .8, .8, .1], .5).tolist() == [True, True, True, False])
check("Vectorized tie rule matches scalar rule", np.array_equal(masks([[.9, .8, .8, .1]], .5)[0], mask([.9, .8, .8, .1], .5)))

# Annual diagnostics and the actual insurer/combined membership lists.
annual, membership = [], []
for y in YEARS:
    e = d[(d.year == y) & (d["T"] >= 100)].sort_values("zip").copy()
    si = e.I/e["T"]
    su = e.U/e["T"]
    mi, mc = mask(si), mask(si+su)
    annual.append({"year": y, "eligible": len(e), "insurer_hotspots": int(mi.sum()),
                   "combined_hotspots": int(mc.sum()), "shared": int((mi & mc).sum()),
                   "retention_pct": retained(mi, mc), "insurer_cutoff_pct": 100*si[mi].min(),
                   "combined_cutoff_pct": 100*(si+su)[mc].min(),
                   "rank_correlation": si.rank().corr((si+su).rank()),
                   "component_rank_correlation": si.rank().corr(su.rank()),
                   "insurer_total": int(e.I.sum()), "policyholder_total": int(e.U.sum())})
    e["insurer_hotspot"], e["combined_hotspot"] = mi, mc
    membership.extend(e[["year", "zip", "county", "T", "I", "U", "insurer_hotspot", "combined_hotspot"]].to_dict("records"))
save(annual, "annual_diagnostics")
save(membership, "membership")
check("Primary definition comparisons reproduced", [r["shared"] for r in annual] == [62, 123, 116, 103]
      and all(r["insurer_hotspots"] == r["combined_hotspots"] == 157 for r in annual))

# Two temporal comparisons: annual universes and a common eligible universe.
temporal = []
for y in range(2018, 2021):
    a = d[(d.year == y) & (d["T"] >= 100)].set_index("zip").sort_index()
    b = d[(d.year == y+1) & (d["T"] >= 100)].set_index("zip").sort_index()
    common = a.index.intersection(b.index)
    for universe in ["Annual eligible universes", "Common eligible ZIPs reranked"]:
        x, z = (a, b) if universe.startswith("Annual") else (a.loc[common], b.loc[common])
        for measure in ["Insurer", "Combined"]:
            sa = x.I/x["T"] if measure == "Insurer" else (x.I+x.U)/x["T"]
            sb = z.I/z["T"] if measure == "Insurer" else (z.I+z.U)/z["T"]
            ha, hb = set(x.index[mask(sa)]), set(z.index[mask(sb)])
            temporal.append({"from_year": y, "to_year": y+1, "universe": universe,
                             "measure": measure, "eligible_from": len(x), "eligible_to": len(z),
                             "common_eligible": len(common), "hotspots_from": len(ha),
                             "hotspots_to": len(hb), "shared": len(ha & hb),
                             "retention_pct": 100*len(ha & hb)/len(ha),
                             "jaccard_pct": 100*len(ha & hb)/len(ha | hb)})
save(temporal, "consecutive_year_overlap")
check("All temporal comparisons present", len(temporal) == 12 and all(0 <= r["retention_pct"] <= 100 for r in temporal))

# Descriptive component swaps on exactly the same 2018/2019 eligible ZIPs.
a = d[(d.year == 2018) & (d["T"] >= 100)].set_index("zip")
b = d[(d.year == 2019) & (d["T"] >= 100)].set_index("zip")
common = a.index.intersection(b.index).sort_values()
a, b = a.loc[common], b.loc[common]
component_rows, values = [], {}
for iy, iydata in [(2018, a), (2019, b)]:
    for uy, uydata in [(2018, a), (2019, b)]:
        si, su = iydata.I/iydata["T"], uydata.U/uydata["T"]
        mi, mc = mask(si), mask(si+su)
        value = retained(mi, mc)
        values[(iy, uy)] = value
        component_rows.append({"insurer_share_year": iy, "policyholder_share_year": uy,
                               "common_eligible": len(common), "insurer_hotspots": int(mi.sum()),
                               "combined_hotspots": int(mc.sum()), "shared": int((mi & mc).sum()),
                               "retention_pct": value})
save(component_rows, "component_swaps")
insurer_part = .5*((values[2019,2018]-values[2018,2018]) + (values[2019,2019]-values[2018,2019]))
policyholder_part = .5*((values[2018,2019]-values[2018,2018]) + (values[2019,2019]-values[2019,2018]))
save([{"comparison": "2018 to 2019 on common eligible ZIPs", "change_pp": values[2019,2019]-values[2018,2018],
       "insurer_component_pp": insurer_part, "policyholder_component_pp": policyholder_part,
       "interpretation": "Average of two swap orders; descriptive accounting, not causal attribution"}], "component_accounting")
check("Component accounting adds exactly to common-sample difference",
      np.isclose(insurer_part+policyholder_part, values[2019,2019]-values[2018,2018]))

# Redraw counts conditional on observed T and observed insurer share.
# rho=0 is binomial. Positive rho yields a beta-binomial with variance
# T*p*(1-p)*(1+(T-1)*rho); rho values are selected stress scenarios only.
simrows, draws_rows, frequencies = [], [], []
for y in YEARS:
    e = d[(d.year == y) & (d["T"] >= 100)].sort_values("zip").copy()
    total = e["T"].to_numpy(dtype=np.int64)
    rate = (e.I/e["T"]).to_numpy()
    original = mask(rate)
    definition_overlap = retained(original, mask((e.I+e.U)/e["T"]))
    for scenario, rho in [("Binomial", 0.), ("Beta-binomial rho 0.001", .001), ("Beta-binomial rho 0.01", .01)]:
        seed = SEED + 100*y + int(100000*rho)
        rng = np.random.Generator(np.random.PCG64(seed))
        obs_ret, pair_ret, selected_sizes, hit = [], [], [], np.zeros(len(e), dtype=np.int64)
        for offset in range(0, DRAWS, 250):
            size = min(250, DRAWS-offset)
            def draw():
                if rho == 0:
                    return rng.binomial(total, rate, size=(size, len(e)))
                p = np.broadcast_to(rate, (size, len(e))).copy()
                interior = (rate > 0) & (rate < 1)
                concentration = 1/rho-1
                p[:, interior] = rng.beta(rate[interior]*concentration,
                                         (1-rate[interior])*concentration,
                                         size=(size, int(interior.sum())))
                return rng.binomial(total, p)
            first, second = draw(), draw()
            if ((first < 0) | (first > total)).any() or ((second < 0) | (second > total)).any():
                raise AssertionError("Simulated count outside bounds")
            ma, mb = masks(first/total), masks(second/total)
            oa = 100*np.sum(ma & original, axis=1)/original.sum()
            ab = 100*np.sum(ma & mb, axis=1)/ma.sum(axis=1)
            obs_ret.extend(oa.tolist()); pair_ret.extend(ab.tolist())
            selected_sizes.extend(ma.sum(axis=1).tolist()); hit += ma.sum(axis=0)
            for k in range(size):
                draws_rows.append({"year": y, "scenario": scenario, "draw": offset+k+1,
                                   "observed_to_draw_retention_pct": oa[k], "draw_to_draw_retention_pct": ab[k],
                                   "first_draw_hotspots": int(ma[k].sum()), "second_draw_hotspots": int(mb[k].sum())})
        obs_ret, pair_ret = np.array(obs_ret), np.array(pair_ret)
        for comparison, arr in [("Observed to draw", obs_ret), ("Draw to draw", pair_ret)]:
            low, med, high = np.quantile(arr, [.025, .5, .975], method="linear")
            simrows.append({"year": y, "scenario": scenario, "rho": rho, "seed": seed,
                            "draws": DRAWS, "comparison": comparison, "eligible": len(e),
                            "observed_hotspots": int(original.sum()), "mean_retention_pct": arr.mean(),
                            "median_retention_pct": med, "lower_2_5_pct": low, "upper_97_5_pct": high,
                            "monte_carlo_se_mean_pp": arr.std(ddof=1)/np.sqrt(DRAWS),
                            "definition_retention_pct": definition_overlap,
                            "minimum_draw_hotspots": min(selected_sizes), "maximum_draw_hotspots": max(selected_sizes)})
        if rho == 0:
            for z, n, i, flag, h in zip(e.zip, total, e.I, original, hit):
                frequencies.append({"year": y, "zip": z, "T": n, "I": i,
                                    "original_insurer_hotspot": bool(flag), "draw_selection_frequency": h/DRAWS})
        print(y, scenario, "mean observed/draw", round(obs_ret.mean(), 4),
              "mean draw/draw", round(pair_ret.mean(), 4), flush=True)
save(simrows, "resampling_summary")
save(draws_rows, "resampling_draws")
save(frequencies, "binomial_selection_frequencies")
check("Complete simulation summaries", len(simrows) == 24 and len(draws_rows) == 4*3*DRAWS)
check("Simulation intervals ordered and bounded", all(0 <= r["lower_2_5_pct"] <= r["median_retention_pct"] <= r["upper_97_5_pct"] <= 100 for r in simrows))
check("Selection frequencies are probabilities", all(0 <= r["draw_selection_frequency"] <= 1 for r in frequencies))
check("Source workbook unchanged", hashlib.md5(source.read_bytes()).hexdigest() == "9c7cd33c1e7780fff7f0ecb497e9d9ad")

metadata = {"seed_base": SEED, "draws_per_year_per_scenario": DRAWS,
            "numpy_version": np.__version__, "pandas_version": pd.__version__,
            "python_version": platform.python_version(), "generator": "PCG64",
            "minimum_T": 100, "top_fraction": .1, "ties": "included",
            "quantiles": "linear empirical 2.5th and 97.5th percentiles; not confidence intervals",
            "source_md5": hashlib.md5(source.read_bytes()).hexdigest(),
            "matched_input_sha256": hashlib.sha256((OUT/"extension_matched_input.csv").read_bytes()).hexdigest(),
            "source_counts_modified": False,
            "interpretation": "Conditional sensitivity scenarios only; no estimated sampling process, reporting error, cross-ZIP dependence or causal attribution"}
(OUT / "ranking_run_metadata.json").write_text(json.dumps(metadata, indent=2))
print("RANKING CHECKS PASSED", len(checks), flush=True)
