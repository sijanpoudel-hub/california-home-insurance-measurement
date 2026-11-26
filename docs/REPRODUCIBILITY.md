# Reproduction status

## What has been checked

The author supplied printed results from local R runs. Those outputs supported arithmetic checks of coverage, descriptive shares, hotspot omission, definition agreement and Census-label sensitivity.

The original California workbook entries for ZIP 93016 were checked by the author against the imported counts. Matching source entries establish faithful extraction; they do not independently validate the reporting origin or insured-property geography.

## What remains

1. Add the saved scripts listed below.
2. Restore the empty Step 10 script with the actual analysis code.
3. Review scripts for explicit dependencies, portable file paths and consistent output names.
4. Record exact input filenames, download dates where known, byte sizes and file hashes.
5. Record R and package versions.
6. Run the entire analysis in a fresh R session using the frozen inputs.
7. Compare regenerated tables with the manuscript and retain the verification record.
8. Only then designate a versioned reproducibility release.

No successful full-repository run is currently claimed.

## Expected original scripts

The following filenames come from the author's local inventory supplied on November 26, 2026. The sequence is provisional until the contents and dependencies are reviewed.

| Order | Relative path | Intended role | Inventory status |
|---|---|---|---|
| 1 | `R/data cleaning and total calculation.R` | Import, cleaning and reconciliation | Reported nonempty; contents not yet reviewed here |
| 2 | `R/step-6 formula.R` | California descriptive shares | Reported nonempty; contents not yet reviewed here |
| 3 | `R/treasery step 7.R` | Federal import and ZIP-year matching | Reported nonempty; contents not yet reviewed here |
| 4 | `R/step 8.R` | Coverage, selection and definition pilot tables | Reported nonempty; contents not yet reviewed here |
| 5 | `R/step-9.R` | Annual hotspots and county comparisons | Reported nonempty; contents not yet reviewed here |
| 6 | `R/step-10.R` | Pooling and definition-agreement checks | Reported empty: 0 bytes |
| 7 | `R/11_submission_audit.R` | Original local geography and script audit | Reported nonempty; portable counterpart supplied in tools |

Preserve the actual saved analysis code before reorganizing filenames. Existing objects in an interactive R session do not demonstrate that the saved scripts can recreate them.

## Portable geography audit

`tools/geography_audit.R` is adapted from the audit that produced the supplied geography tables. Its project root defaults to the current working directory, with an optional `CA_INSURANCE_PROJECT_ROOT` override.

Required derived input:

`data_clean/california_federal_matched_2018_2021.rds`

Required fields include the counts, ZIP, year, county and nonmissing logical federal visibility/usable flags. The script checks keys and count arithmetic, downloads the official Census Gazetteer if absent, repeats the geography sensitivities and records an inventory. It expects the reviewed pilot's omitted set of 24 ZIP-years and 13 ZIP labels; a changed set stops the script for investigation.

The county reference is a manually transcribed public lookup for those 13 labels. It is not a historical USPS delivery-type or insured-property crosswalk.

Expected outputs include:

- `submission_geography_summary.csv`
- `submission_omitted_zip_audit.csv`
- `submission_geography_hotspot_sensitivity.csv`
- `submission_geography_definition_sensitivity.csv`
- `submission_geography_reference_manifest.csv`
- `submission_session_info.txt`
- `submission_script_inventory.csv`

These output names specify the script's behavior. They do not imply that a complete public-repository run has been performed.

## Release record

Before a release, record the Git commit, input fingerprints, session information and table-comparison results together. Do not infer software versions or download dates from a later run.
