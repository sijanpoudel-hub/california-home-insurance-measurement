# Reproduction status

## Uploaded scripts and review

All seven original scripts were uploaded by the author. The restored `step-10.R` contains the original pooling and definition-agreement code; no reconstruction was substituted.

The review found hard-coded Windows project paths. These were replaced with shared configuration in `R/config.R`. The original formulas, eligibility thresholds, grouping rules and cutoff-tie handling were preserved. A failed independent statewide reconciliation now stops execution rather than allowing later steps to continue.

The original files were uploaded to the repository root, so the execution order is:

1. `data cleaning and total calculation.R`
2. `step-6 formula.R`
3. `treasery step 7.R`
4. `step 8.R`
5. `step-9.R`
6. `step-10.R`
7. `11_submission_audit.R`
8. `R/verify_outputs.R`

`run_all.R` parses required files before execution, evaluates each step in a separate environment, and records status. Use a fresh R process for the strongest reproducibility check.

## What the checks establish

The verification script compares regenerated results with 44 reported pilot quantities or groups of quantities: annual counts, denominator availability, federal coverage, hotspot selections, pooled samples, definition agreement and geographic sensitivity.

These are regression checks against previously reported results. Passing them does not independently establish the accuracy of every source record, the equivalence of California and federal populations, or a causal interpretation.

The 16 statewide count comparisons in Step 5 use the separately published official CDI county report. ZIP 93016 is checked against its original workbook entries, which tests extraction rather than reporting origin or property location.

## Current verification status

A successful fresh run has not yet been recorded in this document. The automated workflow attempts the full pipeline using public agency downloads. Its run and artifacts, when available, provide the actual result.

A failed download is different from a failed analytical check. Do not mark the pipeline verified if either prevents completion.

## Inputs and software

The public download helper validates file readability and preserves valid existing inputs. Existing acquisition dates are not inferred. Exact observed byte sizes and MD5 hashes are written to `outputs/input_manifest.csv` after a successful run. These hashes identify file contents; they are not a claim of cryptographic authentication.

Software versions are captured in `outputs/full_run_session_info.txt`. Dependency versions were not retroactively assigned to the author's earlier interactive runs.

## Geographic audit

The audit checks the 13 omitted hotspot ZIP labels against a manually transcribed public county reference and checks all study ZIP labels against the fixed 2020 Census Gazetteer. It does not verify historical USPS delivery types or insured-property coordinates.

The reviewed pilot has 24 omitted hotspot ZIP-years across 13 ZIP labels. A changed omitted set stops the audit for investigation. Original results remain primary; the ZCTA restriction is a separately reranked sensitivity.

The compatibility entry point `tools/geography_audit.R` sources the maintained `11_submission_audit.R`.

## Verification outputs

- `pipeline_status.csv`: the status of every required step.
- `reproducibility_checks.csv`: observed and expected quantities, tolerances and outcomes.
- `input_manifest.csv`: exact inputs used by a successful run.
- `input_acquisition_log.csv`: download-helper observations when that helper is used.
- `full_run_session_info.txt`: actual software information.
- `submission_script_inventory.csv`: saved-script fingerprints.

Keep the run's Git commit and these files together. Before journal submission, reconcile final manuscript tables against the recorded run and inspect the final document layout.
