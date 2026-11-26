# Repository locations; run from this repository or set CA_INSURANCE_PROJECT_ROOT.
source(
  file.path(Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd()),
            "R", "config.R"),
  local = TRUE, encoding = "UTF-8"
)



# Install readxl only if it is not already installed
if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl")
}

library(readxl)

# ------------------------------------------------------------
# 1. File locations
# Use forward slashes in R, even on Windows.
# ------------------------------------------------------------

california_path <- ca_california_path

treasury_path <- ca_treasury_path

# ------------------------------------------------------------
# 2. Check whether R can find the files
# ------------------------------------------------------------

file_check <- data.frame(
  dataset = c("California", "Treasury"),
  file_found = c(
    file.exists(california_path),
    file.exists(treasury_path)
  )
)

print(file_check, row.names = FALSE)

if (!file.exists(california_path)) {
  stop(
    "California workbook was not found. ",
    "Check its location and exact filename."
  )
}

# ------------------------------------------------------------
# 3. List the California workbook's sheets
# ------------------------------------------------------------

california_sheets <- excel_sheets(california_path)

cat("\nCALIFORNIA WORKBOOK: SHEET NAMES\n")
print(california_sheets)

# ------------------------------------------------------------
# 4. Inspect the first 20 rows of each California sheet
#
# col_names = FALSE preserves all possible heading rows.
# col_types = "text" avoids changing ZIP codes during inspection.
# ------------------------------------------------------------

california_previews <- setNames(
  vector("list", length(california_sheets)),
  california_sheets
)

for (sheet_name in california_sheets) {
  
  cat("\n====================================================\n")
  cat("CALIFORNIA SHEET:", sheet_name, "\n")
  cat("====================================================\n")
  
  preview <- read_excel(
    path = california_path,
    sheet = sheet_name,
    col_names = FALSE,
    col_types = "text",
    n_max = 20,
    .name_repair = "unique"
  )
  
  california_previews[[sheet_name]] <- preview
  
  print(preview, n = 20, width = Inf)
}

# ------------------------------------------------------------
# 5. List Treasury sheets for the later matching step
# ------------------------------------------------------------

if (file.exists(treasury_path)) {
  
  cat("\nTREASURY WORKBOOK: SHEET NAMES\n")
  print(excel_sheets(treasury_path))
  
} else {
  
  message(
    "Treasury workbook was not found. ",
    "This does not prevent inspecting the California file."
  )
}


# ============================================================
# STEP 5: IMPORT AND CHECK THE CALIFORNIA DATA
# Main research period: 2018–2021
#
# Missing county:
#   Retain the record and flag it for geographic analysis.
#
# Blocking issues:
#   Duplicate ZIP-year, invalid ZIP format, missing/unreadable
#   counts, negative counts, or noninteger counts.
#
# No records are automatically deleted to fix these issues.
# Missing counts are never replaced with zero.
# ============================================================


# ------------------------------------------------------------
# 1. Install and load packages
# ------------------------------------------------------------

packages <- c("readxl", "dplyr")

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}

library(readxl)
library(dplyr)


# ------------------------------------------------------------
# 2. Define file locations and output folders
# ------------------------------------------------------------

project_path <- ca_project_root

california_path <- ca_california_path

clean_folder <- file.path(project_path, "data_clean")
output_folder <- file.path(project_path, "outputs")

dir.create(
  clean_folder,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  output_folder,
  recursive = TRUE,
  showWarnings = FALSE
)

if (!file.exists(california_path)) {
  stop("California workbook not found. Check the file path.")
}


# ------------------------------------------------------------
# 3. Import the California sheet
#
# Import as text first to preserve the source entries.
# ------------------------------------------------------------

california_raw <- read_excel(
  path = california_path,
  sheet = "New Renew NonRenew",
  col_names = TRUE,
  col_types = "text"
)

cat("\nORIGINAL COLUMN NAMES\n")
print(names(california_raw))

cat("\nTOTAL IMPORTED RECORDS, BEFORE YEAR RESTRICTION\n")
print(nrow(california_raw))


# ------------------------------------------------------------
# 4. Check that the required columns exist
# ------------------------------------------------------------

required_columns <- c(
  "County",
  "ZIP Code",
  "Year",
  "New",
  "Renewed",
  "Insured-Initiated Nonrenewed",
  "Insurer-Initiated Nonrenewed"
)

missing_columns <- setdiff(
  required_columns,
  names(california_raw)
)

if (length(missing_columns) > 0) {
  stop(
    "Expected columns were not found: ",
    paste(missing_columns, collapse = ", ")
  )
}


# ------------------------------------------------------------
# 5. Standardize variable names
#
# Insured-initiated = policyholder-initiated.
# Insurer-initiated = insurance-company-initiated.
#
# Retain new-policy counts for reconciliation.
# New policies are not part of the renewal-outcome denominator.
# ------------------------------------------------------------

california_named <- california_raw %>%
  transmute(
    source_row = row_number() + 1L,
    county = trimws(County),
    zip = trimws(`ZIP Code`),
    year = trimws(Year),
    new = trimws(New),
    renewed = trimws(Renewed),
    insured_nonrenewed =
      trimws(`Insured-Initiated Nonrenewed`),
    insurer_nonrenewed =
      trimws(`Insurer-Initiated Nonrenewed`)
  ) %>%
  mutate(
    across(
      where(is.character),
      ~ na_if(.x, "")
    )
  )

# Preserve the standardized text before numeric conversion.
saveRDS(
  california_named,
  file.path(
    clean_folder,
    "california_source_text_2015_2021.rds"
  )
)


# ------------------------------------------------------------
# 6. Convert years and policy counts to numeric values
#
# Commas are removed from numeric entries.
# Unreadable entries become NA and will be flagged.
# ZIP remains a character variable.
# ------------------------------------------------------------

count_fields <- c(
  "new",
  "renewed",
  "insured_nonrenewed",
  "insurer_nonrenewed"
)

parse_number <- function(x) {
  suppressWarnings(
    as.numeric(gsub(",", "", x, fixed = TRUE))
  )
}

california_numeric <- california_named %>%
  mutate(
    year = suppressWarnings(as.numeric(year)),
    across(
      all_of(count_fields),
      parse_number
    )
  )


# ------------------------------------------------------------
# 7. Restrict the main analysis to 2018–2021
#
# Save excluded records for documentation.
# ------------------------------------------------------------

excluded_period <- california_numeric %>%
  filter(
    is.na(year) |
      !(year %in% 2018:2021)
  )

write.csv(
  excluded_period,
  file.path(
    output_folder,
    "california_rows_outside_main_period.csv"
  ),
  row.names = FALSE,
  na = ""
)

california <- california_numeric %>%
  filter(year %in% 2018:2021) %>%
  mutate(year = as.integer(year))

if (nrow(california) == 0) {
  stop("No records were found for 2018–2021.")
}

missing_years <- setdiff(
  2018:2021,
  unique(california$year)
)

if (length(missing_years) > 0) {
  stop(
    "The following research years are missing: ",
    paste(missing_years, collapse = ", ")
  )
}

cat("\nRECORDS RETAINED FOR 2018–2021\n")
print(nrow(california))


# ------------------------------------------------------------
# 8. Create data-quality flags
#
# ZIP validation checks format only: exactly five digits.
# It does not verify historical postal geography.
#
# Missing county is a warning, not a blocking issue.
# ------------------------------------------------------------

california_checked <- california %>%
  group_by(zip, year) %>%
  mutate(
    flag_duplicate_zip_year = n() > 1L
  ) %>%
  ungroup() %>%
  mutate(
    flag_missing_county = is.na(county),
    
    flag_invalid_zip = (
      is.na(zip) |
        !grepl("^[0-9]{5}$", zip)
    ),
    
    flag_missing_count = if_any(
      all_of(count_fields),
      ~ is.na(.x) | !is.finite(.x)
    ),
    
    flag_negative_count = if_any(
      all_of(count_fields),
      ~ is.finite(.x) & .x < 0
    ),
    
    flag_noninteger_count = if_any(
      all_of(count_fields),
      ~ is.finite(.x) & .x != floor(.x)
    )
  )

blocking_flags <- c(
  "flag_duplicate_zip_year",
  "flag_invalid_zip",
  "flag_missing_count",
  "flag_negative_count",
  "flag_noninteger_count"
)

california_checked <- california_checked %>%
  mutate(
    blocking_issue = if_any(
      all_of(blocking_flags),
      ~ .x
    ),
    
    any_issue = (
      blocking_issue |
        flag_missing_county
    )
  )


# ------------------------------------------------------------
# 9. Produce the quality summary
#
# Counts refer to affected records.
# One record can have more than one flag.
# ------------------------------------------------------------

quality_summary <- california_checked %>%
  summarise(
    records_2018_2021 = n(),
    
    duplicate_zip_year_records =
      sum(flag_duplicate_zip_year),
    
    missing_county_records =
      sum(flag_missing_county),
    
    invalid_zip_records =
      sum(flag_invalid_zip),
    
    missing_or_unreadable_count_records =
      sum(flag_missing_count),
    
    negative_count_records =
      sum(flag_negative_count),
    
    noninteger_count_records =
      sum(flag_noninteger_count),
    
    records_with_any_issue =
      sum(any_issue),
    
    records_with_blocking_issue =
      sum(blocking_issue)
  )

cat("\nDATA-QUALITY SUMMARY\n")

print(
  as.data.frame(quality_summary),
  row.names = FALSE
)

write.csv(
  quality_summary,
  file.path(
    output_folder,
    "california_quality_summary.csv"
  ),
  row.names = FALSE,
  na = ""
)


# ------------------------------------------------------------
# 10. Save review records and the full checked dataset
#
# Missing county records remain in the checked dataset.
# ------------------------------------------------------------

review_records <- california_checked %>%
  filter(any_issue) %>%
  arrange(year, zip, county)

blocking_records <- california_checked %>%
  filter(blocking_issue) %>%
  arrange(year, zip, county)

duplicate_records <- california_checked %>%
  filter(flag_duplicate_zip_year) %>%
  arrange(year, zip, county)

missing_county_records <- california_checked %>%
  filter(flag_missing_county) %>%
  arrange(year, zip)

write.csv(
  review_records,
  file.path(
    output_folder,
    "california_records_needing_review.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  blocking_records,
  file.path(
    output_folder,
    "california_blocking_issue_records.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  duplicate_records,
  file.path(
    output_folder,
    "california_duplicate_zip_year_records.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  missing_county_records,
  file.path(
    output_folder,
    "california_missing_county_records.csv"
  ),
  row.names = FALSE,
  na = ""
)

saveRDS(
  california_checked,
  file.path(
    clean_folder,
    "california_checked_2018_2021.rds"
  )
)


# ------------------------------------------------------------
# 11. Summarize missing county by year
#
# Percentages below refer to ZIP-year records, not policies.
# ------------------------------------------------------------

missing_county_by_year <- california_checked %>%
  group_by(year) %>%
  summarise(
    total_records = n(),
    
    missing_county_records =
      sum(flag_missing_county),
    
    missing_county_percent = round(
      100 * missing_county_records / total_records,
      2
    ),
    
    .groups = "drop"
  )

cat("\nMISSING COUNTY BY YEAR\n")

print(
  as.data.frame(missing_county_by_year),
  row.names = FALSE
)

write.csv(
  missing_county_by_year,
  file.path(
    output_folder,
    "california_missing_county_by_year.csv"
  ),
  row.names = FALSE
)


# ------------------------------------------------------------
# 12. Stop only if blocking issues exist
#
# Do not automatically delete or combine duplicates.
# Do not replace missing counts with zero.
# ------------------------------------------------------------

if (nrow(blocking_records) > 0) {
  
  cat("\nFIRST RECORDS WITH BLOCKING ISSUES\n")
  
  print(
    head(blocking_records, 20),
    width = Inf
  )
  
  stop(
    "Blocking data-quality issues were found. ",
    "Review california_blocking_issue_records.csv. ",
    "This run has not written a final clean dataset."
  )
}

if (nrow(missing_county_records) > 0) {
  
  cat(
    "\nNOTE: ",
    nrow(missing_county_records),
    " records have missing county.\n",
    sep = ""
  )
  
  cat(
    "These records are retained and flagged. ",
    "Investigate county assignment before geographic ",
    "subgroup analysis.\n",
    sep = ""
  )
}


# ------------------------------------------------------------
# 13. Save the cleaned dataset
#
# county_missing preserves the county warning in the final data.
# ------------------------------------------------------------

california_clean <- california_checked %>%
  select(
    zip,
    year,
    county,
    renewed,
    insurer_nonrenewed,
    insured_nonrenewed,
    new,
    source_row,
    county_missing = flag_missing_county
  ) %>%
  arrange(year, zip)

saveRDS(
  california_clean,
  file.path(
    clean_folder,
    "california_clean_2018_2021.rds"
  )
)

write.csv(
  california_clean,
  file.path(
    clean_folder,
    "california_clean_2018_2021.csv"
  ),
  row.names = FALSE,
  na = ""
)


# ------------------------------------------------------------
# 14. Calculate annual totals for reconciliation
#
# These totals come from this workbook.
# They have not yet been reconciled with an independent
# official summary.
# ------------------------------------------------------------

annual_totals <- california_clean %>%
  group_by(year) %>%
  summarise(
    records = n(),
    unique_zips = n_distinct(zip),
    
    new = sum(new),
    renewed = sum(renewed),
    
    insurer_nonrenewed =
      sum(insurer_nonrenewed),
    
    insured_nonrenewed =
      sum(insured_nonrenewed),
    
    missing_county_records =
      sum(county_missing),
    
    .groups = "drop"
  )

cat("\nANNUAL TOTALS FOR RECONCILIATION\n")

print(
  as.data.frame(annual_totals),
  row.names = FALSE
)

write.csv(
  annual_totals,
  file.path(
    output_folder,
    "california_annual_totals_2018_2021.csv"
  ),
  row.names = FALSE
)


# ------------------------------------------------------------
# 15. Display the cleaned data and completion message
# ------------------------------------------------------------

cat("\nFIRST 10 CLEANED RECORDS\n")

print(
  head(california_clean, 10),
  width = Inf
)

cat("\nIMPORT AND INTERNAL VALIDATION COMPLETED\n")
cat("Cleaned data saved in:", clean_folder, "\n")
cat("Review reports saved in:", output_folder, "\n")

cat(
  "\nNext: reconcile the annual totals with compatible ",
  "official summaries before calculating the research ",
  "measures.\n",
  sep = ""
)

# ============================================================
# STEP 5B: RECONCILE WITH OFFICIAL CDI STATEWIDE TOTALS
#
# Checks:
# 1. Cleaned-data totals agree with your annual CSV.
# 2. Both agree with the official 2015–2021 release.
#
# Original cleaned data are not changed.
# ============================================================

library(dplyr)


# ------------------------------------------------------------
# 1. File locations
# ------------------------------------------------------------

project_path <- ca_project_root

output_folder <- file.path(project_path, "outputs")
clean_folder <- file.path(project_path, "data_clean")

annual_path <- file.path(
  output_folder,
  "california_annual_totals_2018_2021.csv"
)

clean_path <- file.path(
  clean_folder,
  "california_clean_2018_2021.rds"
)

if (!file.exists(annual_path) || !file.exists(clean_path)) {
  stop(
    "Required files were not found. ",
    "Run the revised Step 5 import script first."
  )
}


# ------------------------------------------------------------
# 2. Read your saved outputs
# ------------------------------------------------------------

annual_export <- read.csv(
  annual_path,
  check.names = FALSE
)

clean_data <- readRDS(clean_path)

metrics <- c(
  "new",
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed"
)

required <- c("year", metrics)

if (
  !all(required %in% names(annual_export)) ||
  !all(required %in% names(clean_data))
) {
  stop("One of the files is missing a required column.")
}

if (
  anyNA(clean_data$year) ||
  !setequal(unique(clean_data$year), 2018:2021)
) {
  stop("The cleaned dataset does not contain the expected years.")
}

if (
  anyNA(annual_export$year) ||
  nrow(annual_export) != 4 ||
  anyDuplicated(annual_export$year) > 0 ||
  !setequal(annual_export$year, 2018:2021)
) {
  stop("The annual export must contain one row for each year, 2018–2021.")
}

if (
  !all(vapply(clean_data[metrics], is.numeric, logical(1))) ||
  !all(vapply(annual_export[metrics], is.numeric, logical(1)))
) {
  stop("Policy counts must be numeric.")
}

clean_counts <- as.matrix(clean_data[metrics])
export_counts <- as.matrix(annual_export[metrics])

if (
  any(!is.finite(clean_counts)) ||
  any(!is.finite(export_counts)) ||
  any(clean_counts < 0) ||
  any(export_counts < 0) ||
  any(clean_counts != floor(clean_counts)) ||
  any(export_counts != floor(export_counts))
) {
  stop("Missing or invalid counts were found. Review the data.")
}


# ------------------------------------------------------------
# 3. Recalculate totals directly from the cleaned dataset
# ------------------------------------------------------------

annual_from_clean <- clean_data %>%
  group_by(year) %>%
  summarise(
    across(all_of(metrics), sum),
    .groups = "drop"
  ) %>%
  arrange(year)

annual_export <- annual_export %>%
  arrange(year)


# ------------------------------------------------------------
# 4. Enter verified official reference figures
#
# Source:
# CDI, Residential Insurance Policy Analysis by County,
# 2015–2021, Report Year 2022, page 1, State rows.
# ------------------------------------------------------------

official <- data.frame(
  year = 2018:2021,
  
  new = c(
    979638,
    1102130,
    1057402,
    1107169
  ),
  
  renewed = c(
    7546700,
    7540135,
    7631979,
    7621326
  ),
  
  insurer_nonrenewed = c(
    165008,
    234843,
    186440,
    241662
  ),
  
  insured_nonrenewed = c(
    749179,
    787795,
    805787,
    876760
  )
)

source_url <- paste0(
  "https://www.insurance.ca.gov/01-consumers/200-wrr/upload/",
  "Residential-Insurance-Policy-Analysis-by-County-",
  "2015-to-2021-2.pdf"
)

write.csv(
  official,
  file.path(
    output_folder,
    "california_official_reference_totals_2018_2021.csv"
  ),
  row.names = FALSE
)


# ------------------------------------------------------------
# 5. Compare each of the 16 annual counts
#
# Positive difference: your export exceeds the reference.
# Negative difference: your export is below the reference.
# ------------------------------------------------------------

comparison <- bind_rows(
  lapply(metrics, function(metric_name) {
    
    data.frame(
      year = official$year,
      variable = metric_name,
      
      cleaned_data_total =
        annual_from_clean[[metric_name]],
      
      exported_total =
        annual_export[[metric_name]],
      
      official_total =
        official[[metric_name]]
    )
  })
) %>%
  mutate(
    export_minus_cleaned =
      exported_total - cleaned_data_total,
    
    export_minus_official =
      exported_total - official_total,
    
    status = if_else(
      export_minus_cleaned == 0 &
        export_minus_official == 0,
      "MATCH",
      "REVIEW"
    )
  ) %>%
  arrange(year, variable)

cat("\nSTEP 5: ANNUAL RECONCILIATION\n")

print(
  as.data.frame(comparison),
  row.names = FALSE
)

write.csv(
  comparison,
  file.path(
    output_folder,
    "california_step5_reconciliation.csv"
  ),
  row.names = FALSE
)


# ------------------------------------------------------------
# 6. Save definition notes and reconciliation status
# ------------------------------------------------------------

fact_sheet_url <- paste0(
  "https://www.insurance.ca.gov/01-consumers/200-wrr/upload/",
  "CDI-Fact-Sheet-Residential-Insurance-Market-",
  "Policy-Count-Data-December-2022.pdf"
)

all_matched <- all(comparison$status == "MATCH")

status_text <- if (all_matched) {
  paste(
    "PASS: All 16 annual counts agree with the official",
    "reference and the cleaned-data totals."
  )
} else {
  paste(
    "PENDING: At least one annual count differs.",
    "Investigate before declaring reconciliation complete."
  )
}

validation_notes <- c(
  "CALIFORNIA DATA: STEP 5 VALIDATION RECORD",
  "",
  paste("Run date:", Sys.Date()),
  paste("Cleaned dataset records:", nrow(clean_data)),
  paste(
    "Records with missing county:",
    sum(is.na(clean_data$county) |
          trimws(clean_data$county) == "")
  ),
  "",
  status_text,
  "",
  "REFERENCE",
  source_url,
  "Report Year 2022, page 1, statewide voluntary-market rows.",
  "",
  "DEFINITION NOTES",
  paste(
    "The source's reported nonrenewal counts include",
    "midterm cancellations."
  ),
  paste(
    "Starting in 2020, CDI clarified that nonpayment",
    "should be classified as consumer-initiated."
  ),
  paste(
    "Do not interpret renewed plus reported nonrenewal",
    "counts as a verified renewal-eligible population."
  ),
  paste(
    "Missing-county records are retained for statewide",
    "analysis and flagged for geographic review."
  ),
  paste(
    "Matching statewide totals validates aggregation;",
    "it does not validate every ZIP-level value or",
    "establish comparability with Treasury definitions."
  ),
  "",
  "DEFINITION SOURCE",
  fact_sheet_url
)

writeLines(
  validation_notes,
  file.path(
    output_folder,
    "california_step5_validation_notes.txt"
  )
)


# ------------------------------------------------------------
# 7. Print the outcome
# ------------------------------------------------------------

cat("\nRECONCILIATION RESULT\n")
cat(status_text, "\n")

cat(
  "\nMatched comparisons:",
  sum(comparison$status == "MATCH"),
  "of",
  nrow(comparison),
  "\n"
)

if (!all_matched) {
  
  cat("\nCOMPARISONS REQUIRING REVIEW\n")
  
  print(
    as.data.frame(
      comparison %>% filter(status == "REVIEW")
    ),
    row.names = FALSE
  )
  
} else {
  
  cat(
    "\nStep 5 reconciliation has passed.",
    "\nRetain the documented county and definition limitations.",
    "\nUpdate the Step 6 measure definitions before calculating rates.\n"
  )
}

if (!all_matched) {
  stop("Official statewide reconciliation failed; later steps were not run.")
}
