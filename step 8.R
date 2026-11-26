# ============================================================
# STEP 8: PRODUCE THE FIRST THREE RESULTS — CORRECTED VERSION
#
# TABLE 1: Federal visibility coverage
# TABLE 2: All California versus federally visible California
# TABLE 3: Insurer-initiated versus combined shares
#
# Important:
# - California termination counts include cancellations.
# - Measures are descriptive shares of recorded counts.
# - They are not household nonrenewal probabilities.
# - Statewide shares use summed counts, not mean ZIP shares.
# - Missing-county and zero-denominator records are retained.
# - No minimum-count filter is applied at this stage.
# ============================================================


# ------------------------------------------------------------
# 1. Install and load package
# ------------------------------------------------------------

if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}

library(dplyr)


# ------------------------------------------------------------
# 2. Define file locations
# ------------------------------------------------------------

project_path <- paste0(
  "C:/Users/poude/OneDrive/Desktop/my research/",
  "california homeowners insurance issue"
)

clean_folder <- file.path(project_path, "data_clean")
output_folder <- file.path(project_path, "outputs")

matched_path <- file.path(
  clean_folder,
  "california_federal_matched_2018_2021.rds"
)

dir.create(
  output_folder,
  recursive = TRUE,
  showWarnings = FALSE
)

if (!file.exists(matched_path)) {
  stop(
    "Matched dataset not found. ",
    "Complete Step 7 before running this script."
  )
}


# ------------------------------------------------------------
# 3. Load the matched dataset
# ------------------------------------------------------------

matched <- readRDS(matched_path)

required_columns <- c(
  "zip",
  "year",
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed",
  "recorded_count_total",
  "federal_visible"
)

if (!all(required_columns %in% names(matched))) {
  stop("The matched dataset is missing required columns.")
}

if (
  nrow(matched) == 0 ||
  anyNA(matched$year) ||
  !setequal(unique(matched$year), 2018:2021)
) {
  stop("The dataset must contain records for 2018–2021 only.")
}

if (
  !is.character(matched$zip) ||
  anyNA(matched$zip) ||
  any(!grepl("^[0-9]{5}$", matched$zip))
) {
  stop("ZIP codes must be five-character digit strings.")
}

if (
  anyDuplicated(
    matched[c("zip", "year")]
  ) > 0
) {
  stop("Duplicate ZIP-year records were found.")
}

if (
  !is.logical(matched$federal_visible) ||
  anyNA(matched$federal_visible)
) {
  stop(
    "federal_visible must contain TRUE/FALSE ",
    "without missing values."
  )
}


# ------------------------------------------------------------
# 4. Check policy counts and the denominator
# ------------------------------------------------------------

count_fields <- c(
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed",
  "recorded_count_total"
)

if (
  !all(
    vapply(
      matched[count_fields],
      is.numeric,
      logical(1)
    )
  )
) {
  stop("All policy-count variables must be numeric.")
}

counts <- as.matrix(matched[count_fields])

if (
  any(!is.finite(counts)) ||
  any(counts < 0) ||
  any(counts != floor(counts))
) {
  stop("Missing or invalid policy counts were found.")
}

recalculated_total <- (
  matched$renewed +
    matched$insurer_nonrenewed +
    matched$insured_nonrenewed
)

if (
  any(
    matched$recorded_count_total !=
    recalculated_total
  )
) {
  stop("The saved denominator does not equal R + I + U.")
}

cat("\nDATASET LOADED\n")
cat("ZIP-year records:", nrow(matched), "\n")


# ------------------------------------------------------------
# 5. Corrected helper functions
#
# safe_percent works when:
# - numerator and denominator are both individual values;
# - both are vectors;
# - numerator is a vector and denominator is one group total.
#
# Undefined percentages are stored as NA.
# ------------------------------------------------------------

safe_percent <- function(numerator, denominator) {
  
  value <- 100 * numerator / denominator
  
  ifelse(
    denominator > 0 & is.finite(value),
    value,
    NA_real_
  )
}

# Round percentage fields for display only.
# Saved analytical tables retain their numerical precision.

display_table <- function(x) {
  
  x %>%
    mutate(
      across(
        matches("_pct$|_pp$"),
        ~ round(.x, 6)
      )
    ) %>%
    as.data.frame()
}


# ------------------------------------------------------------
# 6. TABLE 1: Federal visibility coverage
#
# Both groups include all their records, including T = 0.
#
# record_share_pct:
#   Group ZIP-year records / all ZIP-year records in that year.
#
# recorded_count_share_pct:
#   Group sum of T / statewide sum of T in that year.
#
# Neither percentage is a share of unique households.
# ------------------------------------------------------------

table1_coverage <- matched %>%
  group_by(year, federal_visible) %>%
  summarise(
    zip_year_records = n(),
    
    positive_denominator_records =
      sum(recorded_count_total > 0),
    
    zero_denominator_records =
      sum(recorded_count_total == 0),
    
    recorded_count_total =
      sum(recorded_count_total),
    
    .groups = "drop"
  ) %>%
  group_by(year) %>%
  mutate(
    record_share_pct = safe_percent(
      zip_year_records,
      sum(zip_year_records)
    ),
    
    recorded_count_share_pct = safe_percent(
      recorded_count_total,
      sum(recorded_count_total)
    )
  ) %>%
  ungroup() %>%
  mutate(
    federal_group = if_else(
      federal_visible,
      "Available",
      "Not available"
    )
  ) %>%
  arrange(year, desc(federal_visible)) %>%
  select(
    year,
    federal_group,
    zip_year_records,
    positive_denominator_records,
    zero_denominator_records,
    recorded_count_total,
    record_share_pct,
    recorded_count_share_pct
  )


# ------------------------------------------------------------
# 7. Validate the coverage percentages
#
# Available + not available must equal 100% in each year.
# This check catches the error in the earlier helper function.
# ------------------------------------------------------------

coverage_checks <- table1_coverage %>%
  group_by(year) %>%
  summarise(
    record_percentage_total =
      sum(record_share_pct),
    
    recorded_count_percentage_total =
      sum(recorded_count_share_pct),
    
    .groups = "drop"
  )

if (
  any(!is.finite(coverage_checks$record_percentage_total)) ||
  any(
    !is.finite(
      coverage_checks$recorded_count_percentage_total
    )
  ) ||
  any(
    abs(
      coverage_checks$record_percentage_total - 100
    ) > 0.00000001
  ) ||
  any(
    abs(
      coverage_checks$recorded_count_percentage_total - 100
    ) > 0.00000001
  )
) {
  stop("Coverage percentages do not add to 100% within each year.")
}

cat("\nTABLE 1: FEDERAL VISIBILITY COVERAGE\n")

print(
  display_table(table1_coverage),
  row.names = FALSE
)

cat("\nCOVERAGE PERCENTAGE CHECKS\n")

print(
  as.data.frame(coverage_checks),
  row.names = FALSE
)


# ------------------------------------------------------------
# 8. Calculate annual counts for both populations
#
# All population:
#   Every California record.
#
# Visible population:
#   California records with federal_visible == TRUE.
#
# Zero-denominator records contribute zero to these sums.
# No ZIP-level percentages are averaged.
# ------------------------------------------------------------

annual_counts <- matched %>%
  group_by(year) %>%
  summarise(
    all_renewed =
      sum(renewed),
    
    all_insurer_count =
      sum(insurer_nonrenewed),
    
    all_policyholder_count =
      sum(insured_nonrenewed),
    
    visible_renewed =
      sum(renewed[federal_visible]),
    
    visible_insurer_count =
      sum(insurer_nonrenewed[federal_visible]),
    
    visible_policyholder_count =
      sum(insured_nonrenewed[federal_visible]),
    
    .groups = "drop"
  ) %>%
  mutate(
    all_recorded_total =
      all_renewed +
      all_insurer_count +
      all_policyholder_count,
    
    visible_recorded_total =
      visible_renewed +
      visible_insurer_count +
      visible_policyholder_count
  ) %>%
  arrange(year)


# ------------------------------------------------------------
# 9. TABLE 2: Geographic selection comparison
#
# Both populations use the SAME California measure:
#   insurer-initiated count / recorded count total.
#
# Difference = visible percentage minus all-record percentage.
#
# Positive difference:
#   The visible subset produces a higher share.
#
# Negative difference:
#   The visible subset produces a lower share.
#
# Differences are in percentage points.
# ------------------------------------------------------------

table2_selection <- annual_counts %>%
  mutate(
    all_insurer_share_pct = safe_percent(
      all_insurer_count,
      all_recorded_total
    ),
    
    visible_insurer_share_pct = safe_percent(
      visible_insurer_count,
      visible_recorded_total
    ),
    
    visible_minus_all_pp =
      visible_insurer_share_pct -
      all_insurer_share_pct
  ) %>%
  select(
    year,
    all_insurer_count,
    visible_insurer_count,
    all_recorded_total,
    visible_recorded_total,
    all_insurer_share_pct,
    visible_insurer_share_pct,
    visible_minus_all_pp
  )

cat("\nTABLE 2: GEOGRAPHIC SELECTION COMPARISON\n")

print(
  display_table(table2_selection),
  row.names = FALSE
)


# ------------------------------------------------------------
# 10. TABLE 3: Definition comparison
#
# Both measures use identical all-California records and T.
#
# Insurer-initiated share:
#   I / T
#
# Combined share:
#   (I + U) / T
#
# Percentage-point difference:
#   100 * U / T
#
# This is a definition comparison, not a causal estimate.
# ------------------------------------------------------------

table3_definitions <- annual_counts %>%
  mutate(
    insurer_share_pct = safe_percent(
      all_insurer_count,
      all_recorded_total
    ),
    
    combined_share_pct = safe_percent(
      all_insurer_count +
        all_policyholder_count,
      all_recorded_total
    ),
    
    combined_minus_insurer_pp =
      combined_share_pct -
      insurer_share_pct
  ) %>%
  select(
    year,
    all_insurer_count,
    all_policyholder_count,
    all_recorded_total,
    insurer_share_pct,
    combined_share_pct,
    combined_minus_insurer_pp
  )

cat("\nTABLE 3: DEFINITION COMPARISON\n")

print(
  display_table(table3_definitions),
  row.names = FALSE
)


# ------------------------------------------------------------
# 11. Save the corrected tables
#
# These replace the previous Step 8 CSV files.
# The underlying matched dataset is not changed.
# ------------------------------------------------------------

write.csv(
  table1_coverage,
  file.path(
    output_folder,
    "step8_table1_coverage.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  table2_selection,
  file.path(
    output_folder,
    "step8_table2_selection_comparison.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  table3_definitions,
  file.path(
    output_folder,
    "step8_table3_definition_comparison.csv"
  ),
  row.names = FALSE,
  na = ""
)


# ------------------------------------------------------------
# 12. Prepare interpretation statistics
#
# The pooled quantities below sum counts across four years.
# They do not count unique policies or unique households.
# ------------------------------------------------------------

total_records <- nrow(matched)

visible_records <- sum(
  matched$federal_visible
)

missing_records <- total_records - visible_records

visible_record_percent <- safe_percent(
  visible_records,
  total_records
)

all_recorded_counts <- sum(
  matched$recorded_count_total
)

visible_recorded_counts <- sum(
  matched$recorded_count_total[
    matched$federal_visible
  ]
)

missing_recorded_counts <- (
  all_recorded_counts -
    visible_recorded_counts
)

visible_count_percent <- safe_percent(
  visible_recorded_counts,
  all_recorded_counts
)

missing_count_percent <- safe_percent(
  missing_recorded_counts,
  all_recorded_counts
)

selection_lines <- vapply(
  seq_len(nrow(table2_selection)),
  function(i) {
    
    x <- table2_selection[i, ]
    
    sprintf(
      paste0(
        "%d: all-record insurer share %.6f%%; ",
        "visible-subset share %.6f%%; ",
        "visible minus all = %+.6f percentage points."
      ),
      x$year,
      x$all_insurer_share_pct,
      x$visible_insurer_share_pct,
      x$visible_minus_all_pp
    )
  },
  character(1)
)

definition_lines <- vapply(
  seq_len(nrow(table3_definitions)),
  function(i) {
    
    x <- table3_definitions[i, ]
    
    sprintf(
      paste0(
        "%d: insurer-initiated share %.4f%%; ",
        "combined share %.4f%%; ",
        "difference %.4f percentage points."
      ),
      x$year,
      x$insurer_share_pct,
      x$combined_share_pct,
      x$combined_minus_insurer_pp
    )
  },
  character(1)
)


# ------------------------------------------------------------
# 13. Generate a short interpretation
#
# Describe the observed results without automatically calling
# them statistically significant, large, or negligible.
# ------------------------------------------------------------

interpretation <- c(
  "STEP 8: PRELIMINARY INTERPRETATION",
  "",
  "Coverage",
  sprintf(
    paste0(
      "The dataset contains %s ZIP-year records for ",
      "2018–2021. Numeric federal nonrenewal values are ",
      "available for %s records (%.2f%%). The remaining ",
      "%s records lack a numeric federal value."
    ),
    format(
      total_records,
      big.mark = ",",
      trim = TRUE
    ),
    format(
      visible_records,
      big.mark = ",",
      trim = TRUE
    ),
    visible_record_percent,
    format(
      missing_records,
      big.mark = ",",
      trim = TRUE
    )
  ),
  sprintf(
    paste0(
      "Across the four years, visible records represent ",
      "%.6f%% of summed California recorded counts. ",
      "Records without a numeric federal value represent ",
      "%.6f%%. These are shares of R + I + U, not unique ",
      "households or policies in force."
    ),
    visible_count_percent,
    missing_count_percent
  ),
  "",
  "Geographic selection comparison",
  selection_lines,
  paste(
    "Both populations use the same California measure.",
    "Their difference describes the effect of restricting",
    "the analysis to federally visible ZIP-year records."
  ),
  "",
  "Definition comparison",
  definition_lines,
  paste(
    "The definition gap follows from including",
    "policyholder-initiated events in the combined",
    "numerator. It is not a separate causal effect."
  ),
  "",
  "Limitations",
  paste(
    "California reported termination counts include",
    "nonrenewals and cancellations. The calculated",
    "shares are descriptive, not probabilities of",
    "nonrenewal or household uninsurance."
  ),
  paste(
    "Classification of nonpayment changed starting",
    "in 2020, limiting simple comparisons across years."
  ),
  paste(
    "Missing federal records are not automatically",
    "attributed to privacy suppression. Federal and",
    "state policy populations and definitions differ."
  ),
  paste(
    "Statewide robustness does not establish accurate",
    "local hotspot identification. That requires",
    "the next analysis, including small-count checks."
  )
)

interpretation_path <- file.path(
  output_folder,
  "step8_preliminary_interpretation.txt"
)

writeLines(
  interpretation,
  interpretation_path
)

cat("\nPRELIMINARY INTERPRETATION\n")
cat(paste(interpretation, collapse = "\n"), "\n")


# ------------------------------------------------------------
# 14. Completion message
# ------------------------------------------------------------

cat("\nSTEP 8 COMPLETED\n")
cat("Coverage percentage checks passed.\n")
cat("Three corrected tables and interpretation saved in:\n")
cat(output_folder, "\n")
cat("The underlying matched dataset was not modified.\n")



cat("\nCOVERAGE PERCENTAGE CHECKS\n")

print(
  as.data.frame(coverage_checks),
  row.names = FALSE
)