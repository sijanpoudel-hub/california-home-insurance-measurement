# Repository locations; run from this repository or set CA_INSURANCE_PROJECT_ROOT.
source(
  file.path(Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd()),
            "R", "config.R"),
  local = TRUE, encoding = "UTF-8"
)

# ============================================================
# STEP 6: CALCULATE THE TWO CALIFORNIA MEASURES
#
# IMPORTANT DEFINITIONS
#
# R = renewed policies
# I = reported insurer-initiated nonrenewals/cancellations
# U = reported policyholder-initiated nonrenewals/cancellations
#
# T = R + I + U
#
# Measures:
#   insurer_share  = I / T
#   combined_share = (I + U) / T
#
# These are descriptive shares of recorded counts.
# They are NOT estimated probabilities of nonrenewal.
#
# When T = 0, both shares are undefined and recorded as NA.
# ============================================================


# ------------------------------------------------------------
# 1. Load the package
# ------------------------------------------------------------

if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}

library(dplyr)


# ------------------------------------------------------------
# 2. Define file locations
# ------------------------------------------------------------

project_path <- ca_project_root

clean_folder <- file.path(project_path, "data_clean")
output_folder <- file.path(project_path, "outputs")

dir.create(
  output_folder,
  recursive = TRUE,
  showWarnings = FALSE
)

clean_path <- file.path(
  clean_folder,
  "california_clean_2018_2021.rds"
)

if (!file.exists(clean_path)) {
  stop(
    "Cleaned dataset not found. ",
    "Complete the revised Step 5 script first."
  )
}


# ------------------------------------------------------------
# 3. Load and check the cleaned dataset
# ------------------------------------------------------------

california_clean <- readRDS(clean_path)

required_columns <- c(
  "zip",
  "year",
  "county",
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed"
)

if (!all(required_columns %in% names(california_clean))) {
  stop("The cleaned dataset is missing required columns.")
}

if (nrow(california_clean) == 0) {
  stop("The cleaned dataset contains no records.")
}

if (
  anyNA(california_clean$year) ||
  !setequal(unique(california_clean$year), 2018:2021)
) {
  stop("The dataset must contain only the years 2018–2021.")
}

if (
  anyDuplicated(
    california_clean[c("zip", "year")]
  ) > 0
) {
  stop("Duplicate ZIP-year records were found.")
}

if (
  !is.character(california_clean$zip) ||
  anyNA(california_clean$zip) ||
  any(!grepl("^[0-9]{5}$", california_clean$zip))
) {
  stop("ZIP codes must be five-character digit strings.")
}

count_fields <- c(
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed"
)

if (
  !all(
    vapply(
      california_clean[count_fields],
      is.numeric,
      logical(1)
    )
  )
) {
  stop("The three policy-count variables must be numeric.")
}

counts <- as.matrix(
  california_clean[count_fields]
)

if (
  any(!is.finite(counts)) ||
  any(counts < 0) ||
  any(counts != floor(counts))
) {
  stop("Missing or invalid counts were found. Review Step 5.")
}


# ------------------------------------------------------------
# 4. Calculate ZIP-year totals and shares
#
# Keep all records, including those with missing county.
# Keep zero-denominator records, but assign NA to their shares.
#
# Existing source variables are preserved.
# ------------------------------------------------------------

california_measures <- california_clean %>%
  mutate(
    recorded_count_total =
      renewed +
      insurer_nonrenewed +
      insured_nonrenewed,
    
    combined_nonrenewal_cancel_count =
      insurer_nonrenewed +
      insured_nonrenewed,
    
    zero_denominator =
      recorded_count_total == 0,
    
    insurer_share = if_else(
      recorded_count_total > 0,
      insurer_nonrenewed / recorded_count_total,
      NA_real_
    ),
    
    combined_share = if_else(
      recorded_count_total > 0,
      combined_nonrenewal_cancel_count /
        recorded_count_total,
      NA_real_
    ),
    
    insurer_share_pct =
      100 * insurer_share,
    
    combined_share_pct =
      100 * combined_share
  ) %>%
  arrange(year, zip)


# ------------------------------------------------------------
# 5. Summarize denominator availability
#
# No minimum-count filter is applied at this stage.
# Small-count sensitivity checks come later.
# ------------------------------------------------------------

denominator_summary <- california_measures %>%
  group_by(year) %>%
  summarise(
    zip_year_records = n(),
    
    zero_denominator_records =
      sum(zero_denominator),
    
    positive_denominator_records =
      sum(recorded_count_total > 0),
    
    positive_denominator_below_100 =
      sum(
        recorded_count_total > 0 &
          recorded_count_total < 100
      ),
    
    missing_county_records =
      sum(
        is.na(county) |
          trimws(county) == ""
      ),
    
    .groups = "drop"
  )

cat("\nDENOMINATOR AND COUNTY SUMMARY\n")

print(
  as.data.frame(denominator_summary),
  row.names = FALSE
)


# ------------------------------------------------------------
# 6. Calculate annual statewide measures
#
# IMPORTANT:
# Sum the counts first, then divide.
# Do not average the ZIP-level percentages.
# ------------------------------------------------------------

state_measures <- california_measures %>%
  group_by(year) %>%
  summarise(
    zip_year_records = n(),
    
    renewed =
      sum(renewed),
    
    insurer_nonrenewed =
      sum(insurer_nonrenewed),
    
    insured_nonrenewed =
      sum(insured_nonrenewed),
    
    recorded_count_total =
      sum(recorded_count_total),
    
    .groups = "drop"
  ) %>%
  mutate(
    combined_nonrenewal_cancel_count =
      insurer_nonrenewed +
      insured_nonrenewed,
    
    insurer_share = if_else(
      recorded_count_total > 0,
      insurer_nonrenewed / recorded_count_total,
      NA_real_
    ),
    
    combined_share = if_else(
      recorded_count_total > 0,
      combined_nonrenewal_cancel_count /
        recorded_count_total,
      NA_real_
    ),
    
    insurer_share_pct =
      100 * insurer_share,
    
    combined_share_pct =
      100 * combined_share
  ) %>%
  arrange(year)


# ------------------------------------------------------------
# 7. Display statewide results
#
# Round only the displayed percentages.
# Saved analytical values retain their precision.
# ------------------------------------------------------------

state_display <- state_measures %>%
  select(
    year,
    renewed,
    insurer_nonrenewed,
    insured_nonrenewed,
    recorded_count_total,
    insurer_share_pct,
    combined_share_pct
  ) %>%
  mutate(
    across(
      c(insurer_share_pct, combined_share_pct),
      ~ round(.x, 4)
    )
  )

cat("\nCALIFORNIA STATEWIDE MEASURES\n")

print(
  as.data.frame(state_display),
  row.names = FALSE
)


# ------------------------------------------------------------
# 8. Display example ZIP-year results
# ------------------------------------------------------------

zip_display <- california_measures %>%
  select(
    zip,
    year,
    county,
    renewed,
    insurer_nonrenewed,
    insured_nonrenewed,
    recorded_count_total,
    insurer_share_pct,
    combined_share_pct,
    zero_denominator
  )

cat("\nFIRST 10 ZIP-YEAR RESULTS\n")

print(
  head(zip_display, 10),
  width = Inf
)


# ------------------------------------------------------------
# 9. Save the results
# ------------------------------------------------------------

# RDS preserves data types, including character ZIP codes.
saveRDS(
  california_measures,
  file.path(
    clean_folder,
    "california_zip_year_measures_2018_2021.rds"
  )
)

write.csv(
  california_measures,
  file.path(
    output_folder,
    "california_zip_year_measures_2018_2021.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  state_measures,
  file.path(
    output_folder,
    "california_state_measures_2018_2021.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  denominator_summary,
  file.path(
    output_folder,
    "california_denominator_summary_2018_2021.csv"
  ),
  row.names = FALSE,
  na = ""
)

# Export zero-denominator records separately for documentation.
write.csv(
  california_measures %>%
    filter(zero_denominator),
  file.path(
    output_folder,
    "california_zero_denominator_records.csv"
  ),
  row.names = FALSE,
  na = ""
)


# ------------------------------------------------------------
# 10. Save the measure definitions
# ------------------------------------------------------------

measure_notes <- c(
  "STEP 6: MEASURE DEFINITIONS",
  "",
  "R: Renewed policies.",
  paste(
    "I: Reported insurer-initiated nonrenewals",
    "and cancellations."
  ),
  paste(
    "U: Reported policyholder-initiated nonrenewals",
    "and cancellations."
  ),
  "T: R + I + U; the sum of these recorded counts.",
  "",
  "Insurer-initiated share: I / T.",
  "Combined share: (I + U) / T.",
  "Percentage versions multiply the shares by 100.",
  "",
  "These are descriptive shares, not nonrenewal probabilities.",
  "The denominator is not verified renewal-eligible exposure.",
  "Zero-denominator shares are recorded as NA, not zero.",
  "Statewide shares use summed counts, not average ZIP shares.",
  "Missing-county records remain in statewide calculations.",
  "No minimum-count filter has been applied at this stage.",
  paste(
    "The classification of nonpayment changed starting",
    "in 2020; interpret changes across years cautiously."
  )
)

writeLines(
  measure_notes,
  file.path(
    output_folder,
    "california_step6_measure_definitions.txt"
  )
)

cat("\nSTEP 6 CALCULATIONS COMPLETED\n")
cat("Results saved in:", output_folder, "\n")
cat(
  "Interpret the measures using the saved definition notes.\n"
)



# Statewide counts and calculated shares
print(
  as.data.frame(state_measures),
  row.names = FALSE
)

# Zero denominators, small counts, and missing counties
print(
  as.data.frame(denominator_summary),
  row.names = FALSE
)
