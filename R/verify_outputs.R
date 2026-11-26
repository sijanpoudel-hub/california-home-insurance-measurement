# Regression checks against the author's reported pilot results.
# These check reproduction, not independent truth of every source record.
source(file.path(Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd()),
                 "R", "config.R"), local = TRUE, encoding = "UTF-8")
out <- file.path(ca_project_root, "outputs")
checks <- list()
check <- function(label, actual, expected, tolerance = 0) {
  passed <- is.numeric(actual) && length(actual) == length(expected) &&
    !anyNA(actual) && all(is.finite(actual)) &&
    all(abs(actual - expected) <= tolerance)
  checks[[length(checks) + 1L]] <<- data.frame(
    check = label, passed = passed,
    actual = paste(format(actual, digits = 12, trim = TRUE), collapse = "; "),
    expected = paste(format(expected, digits = 12, trim = TRUE), collapse = "; "),
    tolerance = tolerance
  )
}
read_output <- function(filename) {
  path <- file.path(out, filename)
  if (!file.exists(path)) stop("Expected output missing: ", filename)
  x <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  if ("year" %in% names(x)) x <- x[order(x$year), , drop = FALSE]
  x
}
state <- read_output("california_state_measures_2018_2021.csv")
check("State years", state$year, 2018:2021)
check("Annual ZIP-year counts", state$zip_year_records, c(2120, 2103, 2154, 2126))
check("Renewed counts", state$renewed, c(7546700, 7540135, 7631979, 7621326))
check("Insurer-initiated counts", state$insurer_nonrenewed, c(165008, 234843, 186440, 241662))
check("Policyholder-initiated counts", state$insured_nonrenewed, c(749179, 787795, 805787, 876760))
check("Annual constructed T", state$recorded_count_total, c(8460887, 8562773, 8624206, 8739748))
reconciliation <- read_output("california_step5_reconciliation.csv")
check("Independent statewide reference matches", sum(reconciliation$status == "MATCH"), 16)
den <- read_output("california_denominator_summary_2018_2021.csv")
check("Zero T records", den$zero_denominator_records, c(63, 93, 48, 48))
check("Missing county records", den$missing_county_records, c(70, 54, 92, 86))
coverage <- read_output("step8_table1_coverage.csv")
visible <- coverage[coverage$federal_group == "Available", , drop = FALSE]
missing <- coverage[coverage$federal_group == "Not available", , drop = FALSE]
check("Visible ZIP-year counts", visible$zip_year_records, c(1558, 1554, 1553, 1553))
check("Unavailable ZIP-year counts", missing$zip_year_records, c(562, 549, 601, 573))
check("Visible T", visible$recorded_count_total, c(8449131, 8549420, 8609766, 8725335))
check("Unavailable T", missing$recorded_count_total, c(11756, 13353, 14440, 14413))
check("Coverage record percentages sum to 100",
      tapply(coverage$record_share_pct, coverage$year, sum), rep(100, 4), 1e-8)
check("Coverage T percentages sum to 100",
      tapply(coverage$recorded_count_share_pct, coverage$year, sum), rep(100, 4), 1e-8)
hot <- read_output("step9_main_hotspot_omission.csv")
check("Main eligible counts", hot$eligible_records, c(1562, 1563, 1566, 1567))
check("Main hotspot counts", hot$hotspots, rep(157, 4))
check("Main omitted hotspot counts", hot$hotspots_no_usable, c(8, 4, 6, 6))
check("Main hotspot T", hot$hotspot_recorded_total, c(170386, 298112, 315997, 342717))
check("Main omitted hotspot T", hot$omitted_hotspot_recorded_total, c(995, 465, 747, 765))
sens <- read_output("step9_hotspot_sensitivity.csv")
check("Planned sensitivity grid has 36 rows", nrow(sens), 36)
s200 <- sens[sens$minimum_count == 200 & sens$top_fraction == .10, ]
check("T >= 200 top-decile omissions", s200$hotspots_no_usable, rep(0, 4))
pool <- read_output("step10_pooled_sample_counts.csv")
check("Pooled sample counts", pool$zip_codes, c(2323, 1968, 1554))
ph <- read_output("step10_pooled_hotspot_summary.csv")
check("Pooled eligible ZIPs", ph$eligible_zip_codes, 1554)
check("Pooled hotspots", ph$hotspots, 156)
check("Pooled incomplete federal histories",
      ph$hotspots_without_complete_federal_history, 4)
check("Pooled hotspot T", ph$hotspot_recorded_total, 1232567)
check("Pooled incomplete-history hotspot T", ph$omitted_hotspot_recorded_total, 1935)
definition <- read_output("step10_definition_hotspot_comparison.csv")
check("Insurer definition hotspot counts", definition$insurer_hotspots, rep(157, 4))
check("Combined definition hotspot counts", definition$combined_hotspots, rep(157, 4))
check("Definition shared hotspots", definition$shared_hotspots, c(62, 123, 116, 103))
check("Definition union hotspots", definition$union_hotspots, c(252, 191, 198, 211))
check("Definition Spearman correlations", definition$spearman_correlation,
      c(.583849, .789369, .734134, .721779), 1e-6)
audit <- read_output("submission_omitted_zip_audit.csv")
check("Distinct omitted ZIP labels", nrow(audit), 13)
check("County-reference agreement", sum(audit$county_reference_match), 13)
check("Omitted ZIP labels with ZCTA match", sum(audit$zcta2020_match), 10)
nonmatches <- sort(as.character(audit$zip[!audit$zcta2020_match]))
check("Nonmatching ZIP labels", as.numeric(nonmatches), c(93016, 93447, 95656))
geo <- read_output("submission_geography_hotspot_sensitivity.csv")
mapped <- geo[geo$sample == "Matching 2020 ZCTA labels", , drop = FALSE]
check("Mapped eligible counts", mapped$eligible_records, c(1554, 1554, 1554, 1558))
check("Mapped hotspot counts", mapped$hotspots, rep(156, 4))
check("Mapped omitted hotspot counts", mapped$omitted_hotspots, c(8, 4, 3, 6))
check("Mapped hotspot T", mapped$hotspot_T, c(170252, 297924, 321583, 346591))
check("Mapped omitted hotspot T", mapped$omitted_hotspot_T, c(995, 465, 363, 765))
gd <- read_output("submission_geography_definition_sensitivity.csv")
gd <- gd[gd$sample == "Matching 2020 ZCTA labels", , drop = FALSE]
check("Mapped definition shared hotspots", gd$shared, c(61, 122, 114, 101))
check("Mapped definition union hotspots", gd$union, c(251, 190, 198, 211))
report <- do.call(rbind, checks)
write.csv(report, file.path(out, "reproducibility_checks.csv"), row.names = FALSE)
print(report[c("check", "passed")], row.names = FALSE)
if (!all(report$passed)) stop("Reported-result regression checks failed; inspect reproducibility_checks.csv.")
cat("\nAll reported-result checks passed:", nrow(report), "\n")
