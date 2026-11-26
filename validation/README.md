# Successful reproduction record

The full analysis succeeded in a fresh GitHub-hosted R session on November 26, 2026. All seven analytical scripts and all **44 reported-result regression checks** passed.

- [Successful workflow run](https://github.com/sijanpoudel-hub/california-home-insurance-measurement/actions/runs/45883659220)
- Tested code commit: `55c69ad6363a904c059d7bed9894f97f826b3bda`
- Workflow job: `reproduce`
- R version: 4.4.2
- Dependency downloads recorded in the successful log: readxl 1.6.0 and dplyr 1.2.1
- Public inputs: downloaded from CDI, Treasury, USDA and the Census Bureau
- [Complete verification package](https://github.com/sijanpoudel-hub/california-home-insurance-measurement/actions/runs/45883659220/artifacts/15147518684)

## Permanent records

- [All 44 checks](reproducibility_checks.csv), including observed values and tolerances.
- [Exact input fingerprints](input_manifest.csv), including URLs, byte sizes, MD5 and observation time.
- [Per-script execution status](pipeline_status.csv).

These CSV records were transcribed programmatically from the successful workflow's printed reports without changing their contents. The complete 23-file workflow package contains aggregate tables, full session information and additional audit records.

The workflow artifact was configured for 30-day retention and reports an expiration of December 26, 2026. The three CSV files in this directory remain in Git independently of that artifact. Download the complete package for a longer-term local record.

Artifact SHA-256 reported by GitHub:

```text
53741efddec350b9c292be847e0c61820afb3f731fc032020eee7abb123aabb9
```

## Scope of verification

Passing establishes that the saved code, using the recorded public-source input copies, reproduced the checked pilot quantities. It does not independently establish every source record's accuracy, historical insured-property geography, federal-state population equivalence, a causal climate effect or household uninsurance.

The fingerprints refer to this clean run. They are not a retroactive claim about the bytes or package versions used in earlier interactive runs.

The first workflow attempt passed syntax checks but stopped before analysis because package installation lacked an explicit mirror. That workflow configuration was corrected before the successful run. No analytical formula or reported target was changed to obtain a pass.
