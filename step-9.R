# Repository locations; run from this repository or set CA_INSURANCE_PROJECT_ROOT.
source(
  file.path(Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd()),
            "R", "config.R"),
  local = TRUE, encoding = "UTF-8"
)

# ============================================================
# STEP 9: HOTSPOT OMISSIONS AND COUNTY CONTEXT
#
# Main specification:
#   T >= 100 recorded counts per ZIP-year.
#   Highest 10% of insurer-initiated shares within each year.
#   Include every tie at the cutoff.
#
# Sensitivity specifications:
#   Minimum counts: 50, 100, 200.
#   Top fractions: 5%, 10%, 20%.
#
# County context:
#   Fixed USDA 2013 Rural-Urban Continuum Codes.
#   Codes 1–3: Metro.
#   Codes 4–9: Nonmetro.
#   Missing/unmatched counties remain separate.
#
# These are descriptive insurance-count measures.
# Hotspots are not proof of household uninsurance.
# ============================================================


# ------------------------------------------------------------
# 1. Packages and file locations
# ------------------------------------------------------------

packages <- c("dplyr", "readxl")

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
}

library(dplyr)
library(readxl)

project_path <- ca_project_root

clean_folder <- file.path(project_path, "data_clean")
output_folder <- file.path(project_path, "outputs")
raw_folder <- file.path(project_path, "data_raw")

dir.create(
  output_folder,
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  raw_folder,
  recursive = TRUE,
  showWarnings = FALSE
)

matched_path <- file.path(
  clean_folder,
  "california_federal_matched_2018_2021.rds"
)

if (!file.exists(matched_path)) {
  stop("The Step 7 matched dataset was not found.")
}


# ------------------------------------------------------------
# 2. Load and check the data
# ------------------------------------------------------------

dat <- readRDS(matched_path)

required <- c(
  "zip",
  "year",
  "county",
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed",
  "recorded_count_total",
  "federal_visible",
  "federal_usable"
)

if (!all(required %in% names(dat))) {
  stop("The matched dataset is missing required columns.")
}

if (
  nrow(dat) == 0 ||
  anyNA(dat$year) ||
  !setequal(unique(dat$year), 2018:2021)
) {
  stop("Check the reporting years and dataset.")
}

if (
  anyDuplicated(dat[c("zip", "year")]) > 0
) {
  stop("Duplicate ZIP-year records were found.")
}

if (
  !is.logical(dat$federal_visible) ||
  !is.logical(dat$federal_usable) ||
  anyNA(dat$federal_visible) ||
  anyNA(dat$federal_usable)
) {
  stop("Federal visibility/usability flags must be nonmissing logical values.")
}

if (any(dat$federal_usable & !dat$federal_visible)) {
  stop("A usable federal value must also be visible.")
}

count_names <- c(
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed",
  "recorded_count_total"
)

if (
  !all(vapply(dat[count_names], is.numeric, logical(1)))
) {
  stop("Policy-count columns must be numeric.")
}

count_matrix <- as.matrix(dat[count_names])

if (
  any(!is.finite(count_matrix)) ||
  any(count_matrix < 0) ||
  any(count_matrix != floor(count_matrix))
) {
  stop("Missing or invalid policy counts were found.")
}

if (
  any(
    dat$recorded_count_total !=
    dat$renewed +
    dat$insurer_nonrenewed +
    dat$insured_nonrenewed
  )
) {
  stop("The denominator does not equal R + I + U.")
}


# ------------------------------------------------------------
# 3. Helpers
# ------------------------------------------------------------

safe_percent <- function(numerator, denominator) {
  
  value <- 100 * numerator / denominator
  
  ifelse(
    denominator > 0 & is.finite(value),
    value,
    NA_real_
  )
}

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

normalize_header <- function(x) {
  tolower(gsub("[^A-Za-z0-9]", "", x))
}

normalize_county <- function(x) {
  
  x <- tolower(trimws(x))
  x <- sub("\\s+county$", "", x)
  x <- gsub("[^a-z0-9]", "", x)
  x[x == ""] <- NA_character_
  
  x
}


# ------------------------------------------------------------
# 4. Download the official 2013 county classification
#
# Keep this source file for reproducibility.
# ------------------------------------------------------------

rucc_url <- paste0(
  "https://ers.usda.gov/media/5769/",
  "2013-rural-urban-continuum-codes.xls?v=91459"
)

rucc_path <- file.path(
  raw_folder,
  "usda_rucc2013.xls"
)

# Check an existing download before reusing it.
rucc_file_valid <- FALSE

if (file.exists(rucc_path)) {
  
  rucc_file_valid <- tryCatch(
    length(excel_sheets(rucc_path)) > 0,
    error = function(e) FALSE
  )
}

if (!rucc_file_valid) {
  
  cat("\nDownloading USDA 2013 county classification...\n")
  
  tryCatch(
    download.file(
      url = rucc_url,
      destfile = rucc_path,
      mode = "wb"
    ),
    error = function(e) {
      
      if (file.exists(rucc_path)) {
        unlink(rucc_path)
      }
      
      stop(
        "The USDA download failed. Check your internet connection. ",
        "The source page is: ",
        "https://ers.usda.gov/data-products/rural-urban-continuum-codes"
      )
    }
  )
}


# ------------------------------------------------------------
# 5. Locate the classification's header row
#
# This avoids assuming that the first row is the header.
# ------------------------------------------------------------

fips_candidates <- c(
  "fips",
  "fipscode",
  "fips2013"
)

rucc_candidates <- c(
  "rucc2013",
  "ruralurbancontinuumcode2013",
  "ruralurbancontinuumcodes2013"
)

rucc_raw <- NULL

for (sheet_name in excel_sheets(rucc_path)) {
  
  preview <- suppressMessages(
    read_excel(
      rucc_path,
      sheet = sheet_name,
      col_names = FALSE,
      col_types = "text",
      n_max = 15
    )
  )
  
  header_rows <- which(
    apply(
      as.matrix(preview),
      1,
      function(row_values) {
        
        keys <- normalize_header(row_values)
        
        any(keys %in% fips_candidates) &&
          any(keys %in% rucc_candidates)
      }
    )
  )
  
  if (length(header_rows) > 0) {
    
    rucc_raw <- read_excel(
      rucc_path,
      sheet = sheet_name,
      skip = header_rows[1] - 1L,
      col_types = "text"
    )
    
    break
  }
}

if (is.null(rucc_raw)) {
  stop("Could not identify the USDA classification header.")
}

names(rucc_raw) <- normalize_header(
  names(rucc_raw)
)

pick_column <- function(candidates, column_names) {
  
  found <- intersect(candidates, column_names)
  
  if (length(found) != 1L) {
    stop("Could not identify one unambiguous USDA column.")
  }
  
  found
}

fips_col <- pick_column(
  fips_candidates,
  names(rucc_raw)
)

rucc_col <- pick_column(
  rucc_candidates,
  names(rucc_raw)
)

county_col <- pick_column(
  c("countyname", "county"),
  names(rucc_raw)
)


# ------------------------------------------------------------
# 6. Create the California county lookup
# ------------------------------------------------------------

fips_text <- trimws(rucc_raw[[fips_col]])

valid_fips <- (
  !is.na(fips_text) &
    grepl("^[0-9]{4,5}$", fips_text)
)

fips_padded <- rep(
  NA_character_,
  length(fips_text)
)

fips_padded[valid_fips] <- sprintf(
  "%05d",
  as.integer(fips_text[valid_fips])
)

rucc_lookup <- data.frame(
  county_fips = fips_padded,
  official_county = rucc_raw[[county_col]],
  rucc2013 = suppressWarnings(
    as.integer(rucc_raw[[rucc_col]])
  ),
  stringsAsFactors = FALSE
) %>%
  filter(
    !is.na(county_fips),
    substr(county_fips, 1, 2) == "06"
  ) %>%
  mutate(
    county_key = normalize_county(official_county)
  )

if (
  nrow(rucc_lookup) != 58 ||
  anyNA(rucc_lookup$county_key) ||
  anyNA(rucc_lookup$rucc2013) ||
  any(!(rucc_lookup$rucc2013 %in% 1:9)) ||
  anyDuplicated(rucc_lookup$county_fips) > 0 ||
  anyDuplicated(rucc_lookup$county_key) > 0
) {
  stop("The California county lookup needs review.")
}

write.csv(
  rucc_lookup,
  file.path(
    output_folder,
    "step9_california_rucc2013_lookup.csv"
  ),
  row.names = FALSE
)


# ------------------------------------------------------------
# 7. Add county context
#
# Match normalized county labels within California.
# Do not infer a county for records with missing county.
# Do not use fuzzy matching for unmatched names.
# ------------------------------------------------------------

original_records <- nrow(dat)

dat <- dat %>%
  mutate(
    county_key = normalize_county(county)
  ) %>%
  left_join(
    rucc_lookup,
    by = "county_key"
  ) %>%
  mutate(
    county_context = case_when(
      is.na(county_key) ~
        "County missing",
      
      is.na(rucc2013) ~
        "County unmatched",
      
      rucc2013 %in% 1:3 ~
        "Metro",
      
      rucc2013 %in% 4:9 ~
        "Nonmetro",
      
      TRUE ~
        "County unmatched"
    )
  )

if (nrow(dat) != original_records) {
  stop("The county join changed the record count.")
}

county_review <- dat %>%
  filter(
    county_context %in%
      c("County missing", "County unmatched")
  )

write.csv(
  county_review,
  file.path(
    output_folder,
    "step9_county_records_for_review.csv"
  ),
  row.names = FALSE,
  na = ""
)

county_match_summary <- dat %>%
  count(county_context, name = "zip_year_records")

cat("\nCOUNTY CLASSIFICATION SUMMARY\n")

print(
  as.data.frame(county_match_summary),
  row.names = FALSE
)


# ------------------------------------------------------------
# 8. Function to identify annual hotspots
#
# Choose k = ceiling(top_fraction * eligible records).
# Take the kth-largest share as the cutoff.
# Include every record equal to or above that cutoff.
#
# Therefore, ties can make the hotspot set larger
# than the nominal top fraction.
# ------------------------------------------------------------

mark_hotspots <- function(
    input_data,
    minimum_count = 100,
    top_fraction = 0.10
) {
  
  eligible <- input_data %>%
    filter(
      recorded_count_total >= minimum_count
    )
  
  if (
    !setequal(unique(eligible$year), 2018:2021)
  ) {
    stop("A specification has no eligible records in at least one year.")
  }
  
  eligible %>%
    mutate(
      insurer_share_calc =
        insurer_nonrenewed / recorded_count_total
    ) %>%
    group_by(year) %>%
    mutate(
      target_hotspots =
        ceiling(top_fraction * n()),
      
      cutoff_share =
        sort(
          insurer_share_calc,
          decreasing = TRUE
        )[first(target_hotspots)],
      
      hotspot =
        insurer_share_calc >= cutoff_share
    ) %>%
    ungroup()
}


# ------------------------------------------------------------
# 9. Function to summarize hotspot omissions
#
# Distinguish:
# - no numeric federal value;
# - published numeric value failing the usability screen.
#
# Main omission measure: no usable federal value.
# ------------------------------------------------------------

summarize_hotspots <- function(x) {
  
  x %>%
    group_by(year) %>%
    summarise(
      eligible_records = n(),
      
      target_hotspots =
        first(target_hotspots),
      
      cutoff_share_pct =
        100 * first(cutoff_share),
      
      hotspots =
        sum(hotspot),
      
      hotspots_no_numeric =
        sum(hotspot & !federal_visible),
      
      hotspots_quality_review =
        sum(
          hotspot &
            federal_visible &
            !federal_usable
        ),
      
      hotspots_no_usable =
        sum(hotspot & !federal_usable),
      
      hotspot_recorded_total =
        sum(recorded_count_total[hotspot]),
      
      omitted_hotspot_recorded_total =
        sum(
          recorded_count_total[
            hotspot & !federal_usable
          ]
        ),
      
      .groups = "drop"
    ) %>%
    mutate(
      actual_hotspot_pct = safe_percent(
        hotspots,
        eligible_records
      ),
      
      hotspot_omission_pct = safe_percent(
        hotspots_no_usable,
        hotspots
      ),
      
      hotspot_count_omission_pct = safe_percent(
        omitted_hotspot_recorded_total,
        hotspot_recorded_total
      )
    )
}


# ------------------------------------------------------------
# 10. Main hotspot analysis: T >= 100, top 10%
# ------------------------------------------------------------

main_ranked <- mark_hotspots(
  dat,
  minimum_count = 100,
  top_fraction = 0.10
)

hotspot_summary <- summarize_hotspots(
  main_ranked
)

hotspot_list <- main_ranked %>%
  filter(hotspot) %>%
  arrange(
    year,
    desc(insurer_share_calc),
    zip
  ) %>%
  select(
    zip,
    year,
    county,
    county_context,
    county_fips,
    rucc2013,
    recorded_count_total,
    insurer_nonrenewed,
    insurer_share_calc,
    cutoff_share,
    federal_visible,
    federal_usable,
    federal_status
  )

write.csv(
  hotspot_summary,
  file.path(
    output_folder,
    "step9_main_hotspot_omission.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  hotspot_list,
  file.path(
    output_folder,
    "step9_main_hotspot_list.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  hotspot_list %>%
    filter(!federal_usable),
  file.path(
    output_folder,
    "step9_omitted_hotspot_list.csv"
  ),
  row.names = FALSE,
  na = ""
)

cat("\nMAIN HOTSPOT OMISSION RESULTS\n")

print(
  display_table(
    hotspot_summary %>%
      select(
        year,
        eligible_records,
        target_hotspots,
        hotspots,
        cutoff_share_pct,
        hotspots_no_usable,
        hotspot_omission_pct,
        hotspot_count_omission_pct
      )
  ),
  row.names = FALSE
)

if (any(hotspot_summary$cutoff_share_pct == 0)) {
  cat(
    "\nNOTE: A hotspot cutoff is zero.",
    "\nTies may include many zero-share records.",
    "\nInspect that year's hotspot definition carefully.\n"
  )
}


# ------------------------------------------------------------
# 11. Planned sensitivity analyses
#
# Save every specification.
# Do not choose the specification with the largest omission
# and present it as the main result.
# ------------------------------------------------------------

specifications <- expand.grid(
  minimum_count = c(50, 100, 200),
  top_fraction = c(0.05, 0.10, 0.20)
)

sensitivity_results <- bind_rows(
  lapply(
    seq_len(nrow(specifications)),
    function(i) {
      
      minimum <- specifications$minimum_count[i]
      fraction <- specifications$top_fraction[i]
      
      ranked <- mark_hotspots(
        dat,
        minimum_count = minimum,
        top_fraction = fraction
      )
      
      summarize_hotspots(ranked) %>%
        mutate(
          minimum_count = minimum,
          top_fraction = fraction,
          specification = if_else(
            minimum == 100 & fraction == 0.10,
            "Main",
            "Sensitivity"
          )
        )
    }
  )
) %>%
  arrange(minimum_count, top_fraction, year)

write.csv(
  sensitivity_results,
  file.path(
    output_folder,
    "step9_hotspot_sensitivity.csv"
  ),
  row.names = FALSE,
  na = ""
)


# ------------------------------------------------------------
# 12. County-context comparisons
#
# Show two samples separately:
# - all records with positive T;
# - records with T >= 100.
#
# These calculate weighted aggregate shares using summed counts.
# Missing/unmatched county groups remain separate.
# ------------------------------------------------------------

geo_samples <- bind_rows(
  dat %>%
    filter(recorded_count_total > 0) %>%
    mutate(sample = "All positive T"),
  
  dat %>%
    filter(recorded_count_total >= 100) %>%
    mutate(sample = "T >= 100")
)

geographic_results <- geo_samples %>%
  group_by(sample, year, county_context) %>%
  summarise(
    zip_year_records = n(),
    
    visible_records =
      sum(federal_visible),
    
    all_insurer_count =
      sum(insurer_nonrenewed),
    
    visible_insurer_count =
      sum(insurer_nonrenewed[federal_visible]),
    
    all_recorded_total =
      sum(recorded_count_total),
    
    visible_recorded_total =
      sum(recorded_count_total[federal_visible]),
    
    .groups = "drop"
  ) %>%
  mutate(
    visible_record_pct = safe_percent(
      visible_records,
      zip_year_records
    ),
    
    visible_count_pct = safe_percent(
      visible_recorded_total,
      all_recorded_total
    ),
    
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
  )

write.csv(
  geographic_results,
  file.path(
    output_folder,
    "step9_county_context_results.csv"
  ),
  row.names = FALSE,
  na = ""
)

cat("\nCOUNTY-CONTEXT RESULTS: ALL POSITIVE T\n")

print(
  display_table(
    geographic_results %>%
      filter(sample == "All positive T") %>%
      select(
        year,
        county_context,
        zip_year_records,
        visible_count_pct,
        all_insurer_share_pct,
        visible_insurer_share_pct,
        visible_minus_all_pp
      )
  ),
  row.names = FALSE
)


# ------------------------------------------------------------
# 13. Calculate nonmetro-minus-metro gaps
#
# Gap change:
#   gap in the visible subset minus gap in all records.
#
# Unknown county records are not assigned to either group.
# ------------------------------------------------------------

metro_results <- geographic_results %>%
  filter(county_context == "Metro") %>%
  transmute(
    sample,
    year,
    metro_all_pct = all_insurer_share_pct,
    metro_visible_pct = visible_insurer_share_pct
  )

nonmetro_results <- geographic_results %>%
  filter(county_context == "Nonmetro") %>%
  transmute(
    sample,
    year,
    nonmetro_all_pct = all_insurer_share_pct,
    nonmetro_visible_pct = visible_insurer_share_pct
  )

geographic_gaps <- full_join(
  metro_results,
  nonmetro_results,
  by = c("sample", "year")
) %>%
  mutate(
    all_nonmetro_minus_metro_pp =
      nonmetro_all_pct - metro_all_pct,
    
    visible_nonmetro_minus_metro_pp =
      nonmetro_visible_pct - metro_visible_pct,
    
    gap_change_pp =
      visible_nonmetro_minus_metro_pp -
      all_nonmetro_minus_metro_pp
  ) %>%
  arrange(sample, year)

write.csv(
  geographic_gaps,
  file.path(
    output_folder,
    "step9_nonmetro_metro_gaps.csv"
  ),
  row.names = FALSE,
  na = ""
)

cat("\nNONMETRO–METRO GAPS\n")

print(
  display_table(
    geographic_gaps %>%
      select(
        sample,
        year,
        all_nonmetro_minus_metro_pp,
        visible_nonmetro_minus_metro_pp,
        gap_change_pp
      )
  ),
  row.names = FALSE
)


# ------------------------------------------------------------
# 14. Save methods and interpretation limits
# ------------------------------------------------------------

methods_notes <- c(
  "STEP 9: METHODS AND LIMITATIONS",
  "",
  "Primary specification: T >= 100; annual highest 10%.",
  "T is renewed plus both reported termination counts.",
  "California termination counts include cancellations.",
  "",
  "Select ceiling(0.10 * eligible records) as the target.",
  "Retain all records tied at the cutoff.",
  "Report actual hotspot counts and percentages.",
  "",
  "Hotspot omission means no usable federal value.",
  "Separate absent numeric values from quality exclusions.",
  "Missingness is not automatically privacy suppression.",
  "",
  "Sensitivity analyses: T >= 50, 100, 200;",
  "top fractions 5%, 10%, 20%.",
  "",
  "County context uses fixed USDA 2013 RUCC codes.",
  "Codes 1–3 are Metro; 4–9 are Nonmetro.",
  "This is county context, not exact ZIP-level rurality.",
  "Counties are matched by normalized names within California.",
  "Missing/unmatched county labels are not imputed.",
  "",
  "Geographic aggregate comparisons show two samples:",
  "all positive T and T >= 100.",
  "Each comparison uses summed California counts.",
  "",
  "Do not interpret hotspots as proven uninsured communities.",
  "A minimum count does not establish rate precision.",
  "These rankings are descriptive, not significance tests.",
  "Removing ZIPs does not change retained ZIP shares.",
  "Federal and California policy populations differ.",
  "The 2020 nonpayment classification change limits trends.",
  "",
  "USDA source:",
  rucc_url,
  "",
  "Source page:",
  "https://ers.usda.gov/data-products/rural-urban-continuum-codes",
  "",
  paste("Run date:", Sys.Date())
)

writeLines(
  methods_notes,
  file.path(
    output_folder,
    "step9_methods_and_limitations.txt"
  )
)

saveRDS(
  main_ranked,
  file.path(
    clean_folder,
    "california_step9_main_ranked_2018_2021.rds"
  )
)

cat("\nSTEP 9 ANALYSIS AND EXPORT COMPLETED\n")
cat("Results saved in:", output_folder, "\n")
cat("Review the main results before interpreting sensitivities.\n")


cat("\n1. COUNTY CLASSIFICATION SUMMARY\n")

print(
  as.data.frame(county_match_summary),
  row.names = FALSE
)


cat("\n2. MAIN HOTSPOT OMISSION RESULTS\n")

print(
  display_table(hotspot_summary),
  row.names = FALSE
)


cat("\n3. NONMETRO–METRO GAPS\n")

print(
  display_table(geographic_gaps),
  row.names = FALSE
)


# ------------------------------------------------------------
# 1. Compare hotspot omission with eligible-sample omission
# ------------------------------------------------------------

eligible_omission_baseline <- main_ranked %>%
  group_by(year) %>%
  summarise(
    eligible_records = n(),
    
    eligible_without_usable =
      sum(!federal_usable),
    
    hotspot_records =
      sum(hotspot),
    
    hotspots_without_usable =
      sum(hotspot & !federal_usable),
    
    .groups = "drop"
  ) %>%
  mutate(
    eligible_omission_pct =
      100 * eligible_without_usable / eligible_records,
    
    hotspot_omission_pct =
      100 * hotspots_without_usable / hotspot_records
  )

cat("\nELIGIBLE-SAMPLE OMISSION BASELINE\n")

print(
  display_table(eligible_omission_baseline),
  row.names = FALSE
)


# ------------------------------------------------------------
# 2. Display the planned sensitivity results
# ------------------------------------------------------------

cat("\nHOTSPOT SENSITIVITY RESULTS\n")

print(
  display_table(
    sensitivity_results %>%
      select(
        minimum_count,
        top_fraction,
        year,
        eligible_records,
        hotspots,
        hotspots_no_usable,
        hotspot_omission_pct,
        hotspot_count_omission_pct
      )
  ),
  row.names = FALSE
)


# ------------------------------------------------------------
# 3. Inspect the omitted hotspot records
# ------------------------------------------------------------

cat("\nOMITTED HOTSPOT RECORDS\n")

print(
  as.data.frame(
    hotspot_list %>%
      filter(!federal_usable) %>%
      select(
        year,
        zip,
        county,
        county_context,
        recorded_count_total,
        insurer_nonrenewed,
        insurer_share_calc
      )
  ),
  row.names = FALSE
)




cat("\nZIP 93016: ALL AVAILABLE STUDY YEARS\n")

outlier_review <- dat %>%
  filter(zip == "93016") %>%
  arrange(year) %>%
  mutate(
    insurer_share_pct = safe_percent(
      insurer_nonrenewed,
      recorded_count_total
    )
  ) %>%
  select(
    any_of("source_row"),
    year,
    zip,
    county,
    renewed,
    insurer_nonrenewed,
    insured_nonrenewed,
    recorded_count_total,
    insurer_share_pct,
    federal_visible
  )

print(
  display_table(outlier_review),
  row.names = FALSE
)



# Check ZIP 93016 directly in the original California workbook.

source_workbook_path <- ca_california_path

source_check <- readxl::read_excel(
  path = source_workbook_path,
  sheet = "New Renew NonRenew",
  col_types = "text"
) %>%
  mutate(
    excel_row = row_number() + 1L
  ) %>%
  filter(
    trimws(`ZIP Code`) == "93016",
    trimws(Year) %in% as.character(2018:2021)
  ) %>%
  select(
    excel_row,
    County,
    `ZIP Code`,
    Year,
    New,
    Renewed,
    `Insured-Initiated Nonrenewed`,
    `Insurer-Initiated Nonrenewed`
  )

cat("\nZIP 93016: ORIGINAL EXCEL ENTRIES\n")

print(
  as.data.frame(source_check),
  row.names = FALSE
)



write.csv(
  source_check,
  file.path(
    output_folder,
    "step9_zip93016_source_check.csv"
  ),
  row.names = FALSE,
  na = ""
)
