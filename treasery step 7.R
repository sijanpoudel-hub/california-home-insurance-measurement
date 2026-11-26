# ============================================================
# STEP 7A: INSPECT THE TREASURY DATA AND DEFINITIONS
# ============================================================

if (!requireNamespace("readxl", quietly = TRUE)) {
  install.packages("readxl")
}

library(readxl)


# ------------------------------------------------------------
# 1. Treasury workbook location
# ------------------------------------------------------------

project_path <- paste0(
  "C:/Users/poude/OneDrive/Desktop/my research/",
  "california homeowners insurance issue"
)

treasury_path <- file.path(
  project_path,
  "Treasury homeowners insurance metrics for 2018–2022.xlsx"
)

if (!file.exists(treasury_path)) {
  stop("Treasury workbook not found. Check the file path.")
}


# ------------------------------------------------------------
# 2. Inspect the data sheet
#
# Read without assigning headings so we can see whether
# the workbook has introductory rows above the actual header.
# Read as text to preserve the original entries.
# ------------------------------------------------------------

treasury_preview <- suppressMessages(
  read_excel(
    path = treasury_path,
    sheet = "Supporting Underlying Metrics",
    col_names = FALSE,
    col_types = "text",
    n_max = 12,
    .name_repair = "unique"
  )
)

cat("\nTREASURY DATA: FIRST 12 ROWS\n")

print(
  treasury_preview,
  n = 12,
  width = Inf
)


# ------------------------------------------------------------
# 3. Inspect the metric definitions
#
# This helps confirm the nonrenewal measure and its units.
# ------------------------------------------------------------

treasury_definitions <- suppressMessages(
  read_excel(
    path = treasury_path,
    sheet = "Metric Definitions",
    col_names = FALSE,
    col_types = "text",
    n_max = 20,
    .name_repair = "unique"
  )
)

cat("\nTREASURY METRIC DEFINITIONS\n")

print(
  treasury_definitions,
  n = 20,
  width = Inf
)



# ============================================================
# STEP 7B: ADD FEDERAL VISIBILITY
#
# Match Treasury to California using ZIP and year.
# Preserve every California record.
#
# Visibility:
#   A finite numeric nonrenewal value is published.
#   Numeric zero counts as visible.
#
# Quality:
#   Nonnumeric entries and unusual numeric values are flagged.
#   Numeric values outside 0–1 remain visible but require review.
#   Their visibility is separate from their analytical usability.
#
# Missing values are never replaced with zero.
# ============================================================


# ------------------------------------------------------------
# 1. Load packages
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
# 2. Define file locations
# ------------------------------------------------------------

project_path <- paste0(
  "C:/Users/poude/OneDrive/Desktop/my research/",
  "california homeowners insurance issue"
)

clean_folder <- file.path(project_path, "data_clean")
output_folder <- file.path(project_path, "outputs")

treasury_path <- file.path(
  project_path,
  "Treasury homeowners insurance metrics for 2018–2022.xlsx"
)

california_path <- file.path(
  clean_folder,
  "california_zip_year_measures_2018_2021.rds"
)

dir.create(
  output_folder,
  recursive = TRUE,
  showWarnings = FALSE
)

if (!file.exists(treasury_path)) {
  stop("Treasury workbook was not found.")
}

if (!file.exists(california_path)) {
  stop("California Step 6 dataset was not found.")
}


# ------------------------------------------------------------
# 3. Load the California Step 6 dataset
# ------------------------------------------------------------

california <- readRDS(california_path)

required_ca <- c(
  "zip",
  "year",
  "county",
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed",
  "recorded_count_total",
  "insurer_share",
  "combined_share"
)

if (!all(required_ca %in% names(california))) {
  stop("The California dataset is missing required columns.")
}

if (
  nrow(california) == 0 ||
  anyNA(california$year) ||
  !setequal(unique(california$year), 2018:2021)
) {
  stop("Check the California records and reporting years.")
}

if (
  !is.character(california$zip) ||
  anyNA(california$zip) ||
  any(!grepl("^[0-9]{5}$", california$zip))
) {
  stop("California ZIP codes must be five-character strings.")
}

if (
  anyDuplicated(
    california[c("zip", "year")]
  ) > 0
) {
  stop("Duplicate California ZIP-year records were found.")
}

# Record the original order for the preservation check.
california$ca_row_id <- seq_len(nrow(california))


# ------------------------------------------------------------
# 4. Import Treasury data using its actual headings
#
# Read as text first to preserve original entries.
# ------------------------------------------------------------

treasury_raw <- read_excel(
  path = treasury_path,
  sheet = "Supporting Underlying Metrics",
  col_names = TRUE,
  col_types = "text"
)

required_federal <- c(
  "ZIP Code",
  "Year",
  "Policy Decile Grouping",
  "Nonrenewal Rate"
)

if (!all(required_federal %in% names(treasury_raw))) {
  stop("Expected Treasury columns were not found.")
}


# ------------------------------------------------------------
# 5. Standardize Treasury ZIP codes
#
# Example:
#   "1001" becomes "01001"
#
# Only digit strings of one to five characters are accepted.
# Other formats are flagged rather than silently altered.
# ------------------------------------------------------------

normalize_zip <- function(x) {
  
  x <- trimws(x)
  
  valid <- (
    !is.na(x) &
      grepl("^[0-9]{1,5}$", x)
  )
  
  result <- rep(NA_character_, length(x))
  
  result[valid] <- sprintf(
    "%05d",
    as.integer(x[valid])
  )
  
  result
}


# ------------------------------------------------------------
# 6. Parse the nonrenewal rate
#
# Treasury numeric cells are decimal ratios:
#   0.01 = 1%
#
# Scientific notation is handled by as.numeric().
# If an entry explicitly ends in %, divide it by 100.
# Original source entries are retained separately.
# ------------------------------------------------------------

parse_federal_rate <- function(x) {
  
  text <- trimws(x)
  
  explicit_percent <- (
    !is.na(text) &
      grepl("%$", text)
  )
  
  number_text <- sub("%$", "", text)
  
  result <- suppressWarnings(
    as.numeric(trimws(number_text))
  )
  
  result[explicit_percent] <-
    result[explicit_percent] / 100
  
  result
}


# ------------------------------------------------------------
# 7. Build the federal matching table
# ------------------------------------------------------------

treasury <- treasury_raw %>%
  transmute(
    federal_source_row = row_number() + 1L,
    
    federal_zip_raw = `ZIP Code`,
    federal_year_raw = Year,
    
    zip = normalize_zip(`ZIP Code`),
    
    year = suppressWarnings(
      as.integer(trimws(Year))
    ),
    
    federal_policy_decile_raw =
      `Policy Decile Grouping`,
    
    federal_nonrenewal_raw =
      `Nonrenewal Rate`,
    
    federal_nonrenewal_rate =
      parse_federal_rate(`Nonrenewal Rate`),
    
    federal_row_present = TRUE
  )


# ------------------------------------------------------------
# 8. Check federal matching keys
#
# Stop if the keys cannot be interpreted safely.
# ------------------------------------------------------------

bad_federal_keys <- treasury %>%
  filter(
    is.na(zip) |
      is.na(federal_year_raw) |
      !grepl(
        "^[0-9]{4}$",
        trimws(federal_year_raw)
      ) |
      is.na(year) |
      !(year %in% 2018:2022)
  )

write.csv(
  bad_federal_keys,
  file.path(
    output_folder,
    "treasury_invalid_matching_keys.csv"
  ),
  row.names = FALSE,
  na = ""
)

if (nrow(bad_federal_keys) > 0) {
  stop(
    "Invalid Treasury ZIP/year entries were found. ",
    "Review treasury_invalid_matching_keys.csv."
  )
}

# Restrict to the years shared with the California analysis.
treasury_main <- treasury %>%
  filter(year %in% 2018:2021)

if (
  !setequal(
    unique(treasury_main$year),
    2018:2021
  )
) {
  stop("One or more required federal reporting years are missing.")
}

federal_duplicates <- treasury_main %>%
  group_by(zip, year) %>%
  filter(n() > 1L) %>%
  ungroup()

write.csv(
  federal_duplicates,
  file.path(
    output_folder,
    "treasury_duplicate_zip_year_records.csv"
  ),
  row.names = FALSE,
  na = ""
)

if (nrow(federal_duplicates) > 0) {
  stop(
    "Duplicate federal ZIP-year records were found. ",
    "Investigate before matching."
  )
}


# ------------------------------------------------------------
# 9. Match federal data to all California records
#
# left_join() preserves the California dataset.
# No minimum-count filter is applied.
# ------------------------------------------------------------

california_federal_matched <- california %>%
  left_join(
    treasury_main,
    by = c("zip", "year")
  ) %>%
  arrange(ca_row_id) %>%
  mutate(
    federal_row_present =
      coalesce(federal_row_present, FALSE),
    
    federal_entry_blank = (
      federal_row_present &
        (
          is.na(federal_nonrenewal_raw) |
            trimws(federal_nonrenewal_raw) == ""
        )
    ),
    
    federal_numeric_published = (
      federal_row_present &
        is.finite(federal_nonrenewal_rate)
    ),
    
    # Visibility refers to published numerical information.
    federal_visible =
      federal_numeric_published,
    
    # Range checks are separate from visibility.
    # Values outside 0–1 are flagged for review,
    # not automatically interpreted as privacy suppression.
    federal_rate_range_review = (
      federal_numeric_published &
        (
          federal_nonrenewal_rate < 0 |
            federal_nonrenewal_rate > 1
        )
    ),
    
    federal_nonnumeric_entry = (
      federal_row_present &
        !federal_entry_blank &
        !federal_numeric_published
    ),
    
    federal_quality_issue = (
      federal_nonnumeric_entry |
        federal_rate_range_review
    ),
    
    # A conservative initial usability flag.
    # Range-flagged values remain in the dataset for review.
    federal_usable = (
      federal_visible &
        !federal_rate_range_review
    ),
    
    federal_nonrenewal_pct =
      100 * federal_nonrenewal_rate,
    
    federal_status = case_when(
      !federal_row_present ~
        "no_federal_zip_year",
      
      federal_entry_blank ~
        "federal_row_blank_value",
      
      federal_nonnumeric_entry ~
        "federal_row_nonnumeric_entry",
      
      federal_rate_range_review ~
        "published_numeric_range_review",
      
      TRUE ~
        "published_numeric"
    )
  )


# ------------------------------------------------------------
# 10. Confirm that California records were preserved
# ------------------------------------------------------------

if (
  nrow(california_federal_matched) !=
  nrow(california)
) {
  stop("The join changed the number of California records.")
}

if (
  !identical(
    california_federal_matched$ca_row_id,
    california$ca_row_id
  )
) {
  stop("The original California record order was not preserved.")
}

if (
  !identical(
    as.data.frame(
      california_federal_matched[required_ca]
    ),
    as.data.frame(
      california[required_ca]
    )
  )
) {
  stop("California source counts or measures changed during matching.")
}

cat("\nMATCH PRESERVATION CHECK\n")
cat("California records before matching:", nrow(california), "\n")
cat(
  "California records after matching:",
  nrow(california_federal_matched),
  "\n"
)
cat("Original California counts and measures preserved: YES\n")


# ------------------------------------------------------------
# 11. Summarize federal visibility by year
# ------------------------------------------------------------

federal_visibility_summary <- california_federal_matched %>%
  group_by(year) %>%
  summarise(
    california_records = n(),
    
    federal_row_present_records =
      sum(federal_row_present),
    
    no_federal_zip_year_records =
      sum(!federal_row_present),
    
    federal_blank_value_records =
      sum(federal_entry_blank),
    
    federal_nonnumeric_entry_records =
      sum(federal_nonnumeric_entry),
    
    federal_visible_records =
      sum(federal_visible),
    
    published_zero_records = sum(
      federal_visible &
        federal_nonrenewal_rate == 0
    ),
    
    numeric_range_review_records =
      sum(federal_rate_range_review),
    
    federal_usable_records =
      sum(federal_usable),
    
    .groups = "drop"
  ) %>%
  mutate(
    federal_visible_percent = round(
      100 * federal_visible_records /
        california_records,
      2
    )
  )

cat("\nFEDERAL VISIBILITY SUMMARY\n")

print(
  as.data.frame(federal_visibility_summary),
  row.names = FALSE
)


# ------------------------------------------------------------
# 12. Count the detailed matching statuses
# ------------------------------------------------------------

federal_status_counts <- california_federal_matched %>%
  count(
    year,
    federal_status,
    name = "records"
  ) %>%
  arrange(year, federal_status)

cat("\nFEDERAL STATUS COUNTS\n")

print(
  as.data.frame(federal_status_counts),
  row.names = FALSE
)


# ------------------------------------------------------------
# 13. Save the matched dataset and review files
# ------------------------------------------------------------

saveRDS(
  california_federal_matched,
  file.path(
    clean_folder,
    "california_federal_matched_2018_2021.rds"
  )
)

write.csv(
  california_federal_matched,
  file.path(
    output_folder,
    "california_federal_matched_2018_2021.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  federal_visibility_summary,
  file.path(
    output_folder,
    "california_federal_visibility_summary_2018_2021.csv"
  ),
  row.names = FALSE
)

write.csv(
  federal_status_counts,
  file.path(
    output_folder,
    "california_federal_status_counts_2018_2021.csv"
  ),
  row.names = FALSE
)

write.csv(
  california_federal_matched %>%
    filter(federal_quality_issue),
  file.path(
    output_folder,
    "california_federal_values_requiring_review.csv"
  ),
  row.names = FALSE,
  na = ""
)


# ------------------------------------------------------------
# 14. Save matching definitions
# ------------------------------------------------------------

matching_notes <- c(
  "STEP 7: FEDERAL VISIBILITY",
  "",
  "Matching keys: five-character ZIP and reporting year.",
  "All California Step 6 records are preserved.",
  "Four-digit federal ZIP entries are padded with a leading zero.",
  "",
  "federal_visible: A finite numeric federal rate is published.",
  "An explicitly published numeric zero counts as visible.",
  "Visibility does not certify the accuracy of a published value.",
  "",
  "Absent ZIP-year, blank value, and nonnumeric entry are separate.",
  "No missing federal value is replaced with zero.",
  "Missingness is not automatically labelled privacy suppression.",
  "",
  "Numeric values outside 0–1 are flagged for review.",
  "They remain visible but fail the initial usability screen.",
  "This screen is an analytical rule, not proof of source error.",
  "",
  "Federal numeric rates are stored as ratios.",
  "Percentage display equals 100 times the ratio.",
  "",
  "Federal and California measures remain separate.",
  "Their event definitions and denominators differ.",
  "Policy decile categories are not used as policy-count weights."
)

writeLines(
  matching_notes,
  file.path(
    output_folder,
    "california_step7_matching_definitions.txt"
  )
)

cat("\nSTEP 7 MATCHING AND EXPORT COMPLETED\n")
cat("Results saved in:", output_folder, "\n")
cat("Review the visibility summary and any flagged values.\n")


print(
  as.data.frame(federal_visibility_summary),
  row.names = FALSE
)

print(
  as.data.frame(federal_status_counts),
  row.names = FALSE
)