# California home insurance measurement

Research archive for **Coverage and Definition Sensitivity in California Home Insurance Measures**.

Author: Sijan Poudel, Georgia State University.

The study examines how geographic availability and event definitions change descriptive California homeowners-insurance measures during 2018–2021. It holds California's counts and definitions fixed when comparing all eligible records with records having usable published federal nonrenewal values.

## Archive status

All seven original analysis scripts are now present, including the author's restored Step 10 script. The scripts have been reviewed and adapted to portable project locations. The original analytical formulas, sample rules and cutoff-tie handling are preserved.

The full pipeline includes 44 regression checks against the author's supplied pilot tables. **A successful fresh run is not yet claimed.** See [reproduction status](docs/REPRODUCIBILITY.md) and the repository's Actions tab for verification results.

## Run the analysis

Download or clone the repository and open R in that folder. Install the dependencies:

```r
install.packages(c("readxl", "dplyr"))
```

Use the original workbooks in the repository root or in `data_raw/`. The [source documentation](data_raw/README.md) identifies the exact names. Alternatively, download public agency copies:

```r
source("tools/download_public_inputs.R", encoding = "UTF-8")
```

Run all steps and reported-result checks:

```r
source("run_all.R", encoding = "UTF-8")
```

For a fresh R process, use this terminal command from the repository folder:

```sh
Rscript --vanilla run_all.R
```

Each step uses its own environment and reads the preceding saved output. The runner stops on a script error or a failed reconciliation. It records pipeline status, input fingerprints, software information and the numerical verification report in `outputs/`.

The download helper checks workbook readability before saving. Agency availability and changes to source files can affect later runs. A reported-result mismatch is a failure to investigate, not an instruction to alter the results.

## Locations

The default project root is the current working directory. Set `CA_INSURANCE_PROJECT_ROOT` to use another folder. Optional `CA_INSURANCE_CALIFORNIA_FILE` and `CA_INSURANCE_TREASURY_FILE` environment variables identify specific existing workbooks.

Different copies in the root and `data_raw/` cause a stop unless an explicit input override selects one. Missing federal values and missing study-year observations are never replaced with zeros.

## Contents

- [Measure definitions](docs/MEASURES.md)
- [Reproduction notes and script order](docs/REPRODUCIBILITY.md)
- [Official data sources](data_raw/README.md)
- [Full-analysis entry point](run_all.R)
- [Reported-result regression checks](R/verify_outputs.R)
- [Geography-audit entry point](tools/geography_audit.R)
- [Citation metadata](CITATION.cff)

Original script filenames are retained at the repository root. `R/config.R` supplies portable locations. The geography-audit helper delegates to `11_submission_audit.R` so there is one maintained audit implementation.

## Interpretation

California's termination counts include cancellations as well as nonrenewals. The constructed denominator R + I + U is not a verified count of unique policies eligible for renewal. Shares are descriptive indices.

California and Treasury cover different policy populations and use different denominators. Differences do not by themselves establish federal data error, household uninsurance, a causal climate effect, or movement into the FAIR Plan.

A fixed 2020 Census ZCTA-label sensitivity tests geographic compatibility. A missing ZCTA match does not establish an invalid postal ZIP.

## Data and citation

Agency datasets remain subject to their source terms. Raw workbooks and derived datasets are not committed. The runner records fingerprints of the actual inputs used; it does not infer the acquisition dates of existing files.

This is a working research archive, not a peer-reviewed publication. Cite the original data agencies and relevant research separately.
