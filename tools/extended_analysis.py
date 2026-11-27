"""Exploratory additions; original annual T>=100/top-10% results remain primary.
Uses freshly downloaded public inputs and the saved matched R panel. No absent
ZIP-year, missing count, or absent federal measure is imputed as zero.
"""
from pathlib import Path
import csv, hashlib, json, math, re, urllib.request
import numpy as np
import pandas as pd
from openpyxl import load_workbook

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"outputs"
OUT.mkdir(exist_ok=True)
YEARS=range(2018,2022)
checks=[]
def check(label, condition, detail=""):
    checks.append({"check":label,"passed":bool(condition),"detail":str(detail)})
    if not condition:
        pd.DataFrame(checks).to_csv(OUT/"extended_independent_checks.csv",index=False)
        raise AssertionError(label+": "+str(detail))
def save(df,name):
    df.to_csv(OUT/("extended_"+name+".csv"),index=False,float_format="%.12g")
def norm(x): return re.sub(r"[^a-z0-9]","",str(x).lower())
def countykey(x):
    if pd.isna(x): return ""
    return norm(re.sub(r"\s+county$","",str(x).strip(),flags=re.I))
def pct(n,d): return 100*n/d if d else float("nan")
def topmask(score,f):
    n=len(score)
    if n==0: raise ValueError("No eligible records")
    cutoff=score.sort_values(ascending=False).iloc[math.ceil(f*n)-1]
    return score>=cutoff
def agreement(d,den="T",f=.1):
    a=d.I/d[den]; b=d.C/d[den]
    ma=topmask(a,f); mb=topmask(b,f)
    shared=int((ma&mb).sum()); union=int((ma|mb).sum())
    return {"eligible":len(d),"insurer_hotspots":int(ma.sum()),
            "combined_hotspots":int(mb.sum()),"shared":shared,"union":union,
            "retention_pct":pct(shared,ma.sum()),"jaccard_pct":pct(shared,union),
            "spearman":a.rank(method="average").corr(b.rank(method="average")),
            "omitted_insurer_hotspots":int((ma&~d.visible).sum()),
            "insurer_hotspot_omission_pct":pct((ma&~d.visible).sum(),ma.sum())}

d=pd.read_csv(OUT/"extension_matched_input.csv",dtype={"zip":str,"county":str})
d=d.rename(columns={"new":"N","renewed":"R","insurer_nonrenewed":"I",
                    "insured_nonrenewed":"U","recorded_count_total":"T"})
for c in ["N","R","I","U","T","year"]:
    d[c]=pd.to_numeric(d[c],errors="raise")
d["C"]=d.I+d.U
d["D"]=d.N+d.R
d["visible"]=d.federal_usable.astype(str).str.lower().map({"true":True,"false":False})
check("Input records and unique keys",len(d)==8503 and not d.duplicated(["zip","year"]).any())
check("Count arithmetic and completeness",not d[["N","R","I","U","T"]].isna().any().any()
      and (d[["N","R","I","U","T"]]>=0).all().all()
      and (d.T if False else d["T"]).equals(d.R+d.I+d.U))
check("Availability is boolean",not d.visible.isna().any())
# Independent source extraction from the original workbook, not an R-derived table.
oldpath=ROOT/"data_raw"/"California ZIP data for 2015–2021.xlsx"
raw=pd.read_excel(oldpath,sheet_name="New Renew NonRenew",dtype={"ZIP Code":str})
raw=raw.rename(columns={"ZIP Code":"zip","Year":"year","New":"N","Renewed":"R",
"Insurer-Initiated Nonrenewed":"I","Insured-Initiated Nonrenewed":"U"})
for c in ["year","N","R","I","U"]:
    raw[c]=pd.to_numeric(raw[c].astype(str).str.replace(",","",regex=False),errors="coerce")
raw=raw[raw.year.isin(YEARS)].copy()
raw.zip=raw.zip.astype(str).str.strip().str.replace(r"\.0$","",regex=True).str.zfill(5)
joined=d.merge(raw[["zip","year","N","R","I","U"]],on=["zip","year"],how="outer",suffixes=("","_raw"),indicator=True)
check("Python workbook import independently matches all R counts",len(joined)==8503
      and (joined._merge=="both").all()
      and all((joined[c]==joined[c+"_raw"]).all() for c in ["N","R","I","U"]))
check("Published annual totals independently reproduced",
      d.groupby("year")[["R","I","U","T"]].sum().to_numpy().tolist()==[
      [7546700,165008,749179,8460887],[7540135,234843,787795,8562773],
      [7631979,186440,805787,8624206],[7621326,241662,876760,8739748]])

# 1. Full definition sensitivity grid; keep the common denominator and same sample.
grid=[]
for year in YEARS:
    for m in [50,100,200]:
        e=d[(d.year==year)&(d["T"]>=m)].copy()
        for f in [.05,.10,.20]:
            grid.append({"year":year,"minimum_T":m,"top_fraction":f,**agreement(e,f=f)})
grid=pd.DataFrame(grid); save(grid,"definition_grid")
base=grid[(grid.minimum_T==100)&(grid.top_fraction==.1)].sort_values("year")
check("Independent primary definition overlaps",base.shared.tolist()==[62,123,116,103])
check("Definition sensitivity contains all 36 specifications",len(grid)==36)
# Retain ZIP membership for review, rather than only summary percentages.
membership=[]
for year in YEARS:
    e=d[(d.year==year)&(d["T"]>=100)].copy()
    e["insurer_hotspot"]=topmask(e.I/e["T"],.1)
    e["combined_hotspot"]=topmask(e.C/e["T"],.1)
    for row in e[e.insurer_hotspot|e.combined_hotspot].itertuples():
        membership.append({"year":year,"zip":row.zip,"county":row.county,
        "T":row.T if False else getattr(row,"T"),"I":row.I,"U":row.U,
        "insurer_hotspot":row.insurer_hotspot,"combined_hotspot":row.combined_hotspot})
save(pd.DataFrame(membership),"definition_membership")

# 2. Denominator sensitivity: D = new + renewed, an agency-used descriptive
# count normalizer. It is not a year-end stock or a verified at-risk cohort.
# The T>=100 rule stays FIXED; require D>0 for both scores in paired comparisons.
denrows=[]; denstate=[]; exclusions=[]
for year in YEARS:
    y=d[d.year==year].copy()
    for name in ["T","D"]:
        for label,z in [("All",y[y[name]>0]),("Visible",y[(y[name]>0)&y.visible])]:
            denstate.append({"year":year,"denominator":name,"sample":label,
               "records":len(z),"denominator_total":int(z[name].sum()),
               "insurer_pct":pct(z.I.sum(),z[name].sum()),
               "combined_pct":pct(z.C.sum(),z[name].sum())})
    e=y[(y["T"]>=100)&(y.D>0)].copy()
    exclusions.append({"year":year,"T100_eligible":int((y["T"]>=100).sum()),
                       "excluded_D_zero":int(((y["T"]>=100)&(y.D<=0)).sum()),
                       "paired_eligible":len(e)})
    for f in [.05,.1,.2]:
        # Different numerator definitions within each denominator.
        for den in ["T","D"]:
            denrows.append({"year":year,"comparison":"Insurer versus combined",
                "denominator":den,"top_fraction":f,**agreement(e,den,f)})
        # Same numerator, changing only denominator, on identical records.
        for num in ["I","C"]:
            a=topmask(e[num]/e["T"],f); b=topmask(e[num]/e.D,f)
            denrows.append({"year":year,"comparison":"Denominator change",
            "denominator":num,"top_fraction":f,"eligible":len(e),
            "insurer_hotspots":int(a.sum()),"combined_hotspots":int(b.sum()),
            "shared":int((a&b).sum()),"union":int((a|b).sum()),
            "retention_pct":pct((a&b).sum(),a.sum()),
            "jaccard_pct":pct((a&b).sum(),(a|b).sum()),
            "spearman":(e[num]/e["T"]).rank().corr((e[num]/e.D).rank()),
            "omitted_insurer_hotspots":int((a&~e.visible).sum()),
            "insurer_hotspot_omission_pct":pct((a&~e.visible).sum(),a.sum())})
save(pd.DataFrame(denrows),"denominator_comparisons")
save(pd.DataFrame(denstate),"denominator_statewide")
save(pd.DataFrame(exclusions),"denominator_exclusions")
denstate=pd.DataFrame(denstate)
denagg=[]
for year in YEARS:
    for den in ["T","D"]:
        a=denstate[(denstate.year==year)&(denstate.denominator==den)&(denstate["sample"]=="All")].iloc[0]
        v=denstate[(denstate.year==year)&(denstate.denominator==den)&(denstate["sample"]=="Visible")].iloc[0]
        denagg.append({"year":year,"denominator":den,"all_insurer_pct":a.insurer_pct,
        "visible_insurer_pct":v.insurer_pct,"selection_difference_pp":v.insurer_pct-a.insurer_pct})
save(pd.DataFrame(denagg),"denominator_selection")
check("Independent primary selection effects match manuscript",
      np.allclose(pd.DataFrame(denagg).query('denominator == "T"').selection_difference_pp,
                  [-.001606,-.005062,-.004516,-.001644],atol=.000001,rtol=0))
check("Independent primary hotspot omissions",base.omitted_insurer_hotspots.tolist()==[8,4,6,6])

# 3. Leave each known county out; missing-county records remain in statewide totals.
lookup=pd.read_csv(OUT/"step9_california_rucc2013_lookup.csv")
codes=dict(zip(lookup.county_key,lookup.rucc2013))
d["county_key"]=d.county.map(countykey)
d["context"]=d.county_key.map(codes).map(lambda q: "Unknown" if pd.isna(q)
                                                    else "Metro" if q<=3 else "Nonmetro")
check("County matching is complete for named records",
      ((d.county_key=="")|(d.context!="Unknown")).all())
def agg(x):
    a=x[x["T"]>0];v=a[a.visible]
    result={"all_insurer_pct":pct(a.I.sum(),a["T"].sum()),
    "visible_insurer_pct":pct(v.I.sum(),v["T"].sum())}
    result["selection_difference_pp"]=result["visible_insurer_pct"]-result["all_insurer_pct"]
    for pop,z in [("all",a),("visible",v)]:
        shares={}
        for context in ["Metro","Nonmetro"]:
            q=z[z.context==context]; shares[context]=pct(q.I.sum(),q["T"].sum())
        result[pop+"_nonmetro_minus_metro_pp"]=shares["Nonmetro"]-shares["Metro"]
    result["gap_change_pp"]=result["visible_nonmetro_minus_metro_pp"]-result["all_nonmetro_minus_metro_pp"]
    e=x[x["T"]>=100]
    return {**result,**agreement(e)}
loc=[]
for year in YEARS:
    y=d[d.year==year]
    for excluded in ["NONE"]+sorted(k for k in d.county_key.unique() if k):
        q=y if excluded=="NONE" else y[y.county_key!=excluded]
        loc.append({"year":year,"excluded_county":excluded,**agg(q)})
loc=pd.DataFrame(loc);save(loc,"leave_one_county_out")
check("Leave-one-county-out covers all 58 counties and baseline in all years",len(loc)==4*59)
regime=[]
for label,years in [("2018-2019 before clarification",[2018,2019]),("2020-2021 after clarification",[2020,2021])]:
    z=base[base.year.isin(years)]
    regime.append({"reporting_period":label,"minimum_retention_pct":z.retention_pct.min(),
                   "maximum_retention_pct":z.retention_pct.max(),
                   "note":"Annual results grouped for description; no causal reporting-change estimate."})
save(pd.DataFrame(regime),"reporting_regime_summary")

# 4. Later-release reconciliation. Preserve the later workbook and its full
# inventory. Differences are labelled cross-release, not assumed data errors.
laterurl="https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Insurance-Voluntary-Market-New-Renew-NonRenew-by-ZIP-2020-2023.xlsx"
laterpath=ROOT/"data_raw"/"California_ZIP_2020_2023.xlsx"
request=urllib.request.Request(laterurl,headers={"User-Agent":"Mozilla/5.0 research replication"})
with urllib.request.urlopen(request,timeout=120) as response:
    laterpath.write_bytes(response.read())
wb=load_workbook(laterpath,read_only=True,data_only=True)
inventory={}
candidates=[]
for sheet in wb:
    preview=list(sheet.iter_rows(min_row=1,max_row=18,values_only=True))
    inventory[sheet.title]=[[str(v) if v is not None else "" for v in r] for r in preview]
    for hi,r in enumerate(preview):
        keys=[norm(v) if v is not None else "" for v in r]
        if "year" in keys and any("zip" in k for k in keys) and "renewed" in keys and "new" in keys:
            candidates.append((sheet.title,hi,keys))
(OUT/"extended_later_workbook_inventory.json").write_text(json.dumps(inventory,indent=2))
print("LATER_WORKBOOK_HEADERS",json.dumps(inventory))
if len(candidates)!=1:
    raise ValueError("Review later-release sheet selection: "+repr(candidates))
sheet,hi,keys=candidates[0]
def col(which):
    if which=="zip": matches=[i for i,k in enumerate(keys) if k in ["zip","zipcode"]]
    elif which in ["year","new","renewed"]: matches=[i for i,k in enumerate(keys) if k==which]
    elif which=="C": matches=[i for i,k in enumerate(keys) if "nonrenew" in k and "insurerinitiated" not in k and "insuredinitiated" not in k]
    elif which=="county": matches=[i for i,k in enumerate(keys) if k=="county"]
    if len(matches)!=1: raise ValueError("Ambiguous later column "+which+": "+repr(keys))
    return matches[0]
ix={k:col(k) for k in ["zip","year","new","renewed","C","county"]}
records=[]
for r in wb[sheet].iter_rows(min_row=hi+2,values_only=True):
    if all(v is None for v in r):continue
    try:y=int(float(r[ix["year"]]))
    except (TypeError,ValueError):continue
    if y not in [2020,2021]:continue
    zipval=r[ix["zip"]]
    if zipval is None: raise ValueError("Later release missing ZIP")
    z=str(zipval).strip()
    if re.fullmatch(r"\d+\.0",z):z=z[:-2]
    z=z.zfill(5)
    if not re.fullmatch(r"\d{5}",z): raise ValueError("Later ZIP needs review: "+z)
    row={"zip":z,"year":y,"county_later":r[ix["county"]]}
    for name,key in [("N","new"),("R","renewed"),("C","C")]:
        val=r[ix[key]]
        if val is None:raise ValueError("Blank later count; no zero imputation")
        n=float(str(val).replace(",",""))
        if not math.isfinite(n) or n<0 or n!=int(n):raise ValueError("Invalid later count")
        row[name]=int(n)
    records.append(row)
later=pd.DataFrame(records)
check("Later-release overlap keys are unique",not later.duplicated(["zip","year"]).any())
comparison=d[d.year.isin([2020,2021])][["zip","year","N","R","C","county"]].merge(
    later,on=["zip","year"],how="outer",suffixes=("_old","_later"),indicator=True)
save(comparison,"release_zip_differences")
rev=[];keyrows=[]
for y in [2020,2021]:
    z=comparison[comparison.year==y]
    keyrows.append({"year":y,**{k:int((z._merge==k).sum()) for k in ["both","left_only","right_only"]}})
    for scope in ["All records in each release","Common ZIP-year keys"]:
        a=d[d.year==y];b=later[later.year==y]
        if scope=="Common ZIP-year keys":
            common=set(z.loc[z._merge=="both","zip"]);a=a[a.zip.isin(common)];b=b[b.zip.isin(common)]
        for metric in ["N","R","C"]:
            old=int(a[metric].sum());new=int(b[metric].sum())
            commonz=z[z._merge=="both"]
            rev.append({"year":y,"sample":scope,"metric":metric,"old_count":old,"later_count":new,
            "difference":new-old,"change_pct":pct(new-old,old),
            "common_keys_with_changed_count":int((commonz[metric+"_old"]!=commonz[metric+"_later"]).sum())})
save(pd.DataFrame(rev),"release_reconciliation")
save(pd.DataFrame(keyrows),"release_key_coverage")
manifest={"url":laterurl,"filename":laterpath.name,"bytes":laterpath.stat().st_size,
          "sha256":hashlib.sha256(laterpath.read_bytes()).hexdigest(),
          "sheet":sheet,"headers":keys,
          "interpretation":"Compare combined categories only; later release does not identify I and U separately. Differences can reflect revised reporting, DIC separation, flat-cancellation changes, and geography. Do not splice releases or allocate later combined counts into insurer/policyholder categories."}
(OUT/"extended_later_input_manifest.json").write_text(json.dumps(manifest,indent=2))
pd.DataFrame(checks).to_csv(OUT/"extended_independent_checks.csv",index=False)
print("EXTENDED_ANALYSIS_COMPLETED",len(checks),"checks passed")
for name in ["definition_grid","denominator_comparisons","denominator_selection","release_reconciliation"]:
    t=pd.read_csv(OUT/("extended_"+name+".csv"))
    print("RESULT",name)
    print(t.to_string(index=False))
print("LEAVE_ONE_COUNTY_OUT_RANGES")
print(loc[loc.excluded_county!="NONE"][["selection_difference_pp","retention_pct","insurer_hotspot_omission_pct","gap_change_pp"]].agg(["min","max"]).to_string())
