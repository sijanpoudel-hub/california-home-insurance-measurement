"""Retrieve the pinned historical agency inputs with bounded network timeouts.

Use the companion R downloader afterwards to validate workbook sheets and write
its acquisition record. Stop if an agency changes a file: do not silently use
new bytes for the historical benchmark.
"""
from pathlib import Path
import hashlib
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "data_raw"
DEST.mkdir(exist_ok=True)
SOURCES = [
    ("California ZIP data for 2015–2021.xlsx",
     "https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Property-Voluntary-Market-New-Renew-NonRenew-by-ZIP-2015-2021.xlsx",
     "9c7cd33c1e7780fff7f0ecb497e9d9ad"),
    ("Treasury homeowners insurance metrics for 2018–2022.xlsx",
     "https://home.treasury.gov/system/files/311/Supporting_Underlying_Metrics_and_Disclaimer_for_Analyses_of_US_Homeowners_Insurance_Markets_2018-2022.xlsx",
     "bc2fecb64e97b2f15d53b33f87e8833f"),
    ("usda_rucc2013.xls",
     "https://ers.usda.gov/media/5769/2013-rural-urban-continuum-codes.xls?v=91459",
     "c9c6f5b4c802429ee7c4f2d4646a6f1d"),
    ("2020_Gaz_zcta_national.zip",
     "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_zcta_national.zip",
     "478b295f5279b7c9baebbc3bc7292605")
]
for name, url, expected in SOURCES:
    path = DEST / name
    if path.exists():
        if hashlib.md5(path.read_bytes()).hexdigest() != expected:
            raise RuntimeError("Existing source differs from pinned version: " + name)
        print("Verified existing pinned source:", name, flush=True)
        continue
    for attempt in range(1, 4):
        try:
            print("Downloading:", name, "attempt", attempt, flush=True)
            request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 research replication"})
            with urllib.request.urlopen(request, timeout=45) as response:
                data = response.read()
            break
        except Exception:
            if attempt == 3:
                raise
    if hashlib.md5(data).hexdigest() != expected:
        raise RuntimeError("Agency source changed; investigate before using: " + name)
    path.write_bytes(data)
    print("Downloaded and verified pinned source:", name, len(data), flush=True)
