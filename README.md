# California home insurance measurement

Research archive for **Coverage and Definition Sensitivity in California Home Insurance Measures**.

Author: Sijan Poudel, Georgia State University.

This study examines how geographic availability and event definitions change descriptive California homeowners-insurance measures during 2018–2021. It holds California's counts and definitions fixed when comparing all eligible records with records having usable published federal nonrenewal values.

## Archive status

**Work in progress. The full analysis is not yet reproducible from this repository.**

The repository currently provides documentation and a portable geography-audit script. The original saved analysis scripts and exact input fingerprints still need to be added and checked in a fresh R session. The local script inventory supplied on November 26, 2026 showed an empty `R/step-10.R`; that script must be restored before a reproducibility release.

The reported pilot calculations have been reviewed from printed R results. No complete run of the public repository has been verified.

## Contents

- [Measure definitions](docs/MEASURES.md)
- [Reproduction status and expected scripts](docs/REPRODUCIBILITY.md)
- [Official data sources and input requirements](data_raw/README.md)
- [Portable geography audit](tools/geography_audit.R)
- [Citation metadata](CITATION.cff)

The geography audit requires the matched dataset created by the earlier analysis. It does not replace the import, cleaning, matching or primary-analysis scripts.

## Research design

The main analysis uses 2018–2021 California records. Local hotspot analyses require at least 100 constructed recorded counts in a ZIP-year and select the highest 10% of insurer-initiated count shares, retaining cutoff ties. Alternative minimum counts and top fractions are separate sensitivity analyses.

Geographic sensitivity uses exact ZIP-label membership in the fixed 2020 Census ZCTA Gazetteer. A missing ZCTA match does not establish an invalid postal ZIP.

## Interpretation

California's reported termination counts include cancellations as well as nonrenewals. The study's constructed denominator is not a verified count of unique policies eligible for renewal. The resulting shares are descriptive indices.

California and Treasury cover different policy populations and use different denominators. Differences do not by themselves establish federal data error, household uninsurance, a causal climate effect, or movement into the FAIR Plan.

## Using the geography audit

Install `dplyr` in R, download or clone this repository, and open R in the repository root. Place the previously generated matched dataset at:

```text
data_clean/california_federal_matched_2018_2021.rds
```

Then run:

```r
source("tools/geography_audit.R")
```

Alternatively, set the `CA_INSURANCE_PROJECT_ROOT` environment variable to the existing project folder before sourcing the script. It writes audit tables, a reference-file fingerprint, session information and a saved-script inventory to `outputs/`.

The portable script has been reviewed as text; the modified path handling has not yet been executed in a fresh R session.

## Data and citation

Agency datasets remain subject to their source terms. Raw workbooks and derived datasets are not included in this initial archive. Follow the [input documentation](data_raw/README.md) and cite the agencies and relevant research separately.

This is a working code archive, not a peer-reviewed publication or a final reproducibility release.
