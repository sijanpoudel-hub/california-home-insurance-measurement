# Repository locations; run from this repository or set CA_INSURANCE_PROJECT_ROOT.
source(
  file.path(Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd()),
            "R", "config.R"),
  local = TRUE, encoding = "UTF-8"
)

# ============================================================
# SUBMISSION AUDIT: GEOGRAPHY AND CODE INVENTORY
# Save as: 11_submission_audit.R
#
# Original datasets and results are preserved.
# ZCTA membership is a mapping check, not postal validity.
# The ZCTA-restricted analyses are additional sensitivities.
# ============================================================

if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}
library(dplyr)

project_path <- ca_project_root
raw_folder <- file.path(project_path, "data_raw")
output_folder <- file.path(project_path, "outputs")
dir.create(raw_folder, recursive = TRUE, showWarnings = FALSE)
dir.create(output_folder, recursive = TRUE, showWarnings = FALSE)

matched_path <- file.path(
  project_path, "data_clean",
  "california_federal_matched_2018_2021.rds"
)
if (!file.exists(matched_path)) stop("Matched dataset not found.")
audit_data <- readRDS(matched_path)

required <- c(
  "zip", "year", "county", "renewed",
  "insurer_nonrenewed", "insured_nonrenewed",
  "recorded_count_total", "federal_visible", "federal_usable"
)
if (!all(required %in% names(audit_data))) {
  stop("Required columns are missing.")
}
if (
  anyNA(audit_data$zip) || anyNA(audit_data$year) ||
  anyDuplicated(audit_data[c("zip", "year")]) > 0 ||
  !setequal(unique(audit_data$year), 2018:2021)
) stop("Review the matching keys or years.")

for (flag in c("federal_visible", "federal_usable")) {
  if (!is.logical(audit_data[[flag]]) || anyNA(audit_data[[flag]])) {
    stop("Federal flags must be nonmissing logical values.")
  }
}
count_fields <- c(
  "renewed", "insurer_nonrenewed",
  "insured_nonrenewed", "recorded_count_total"
)
if (!all(vapply(audit_data[count_fields], is.numeric, logical(1)))) {
  stop("Count fields must be numeric.")
}
counts <- as.matrix(audit_data[count_fields])
if (
  any(!is.finite(counts)) || any(counts < 0) ||
  any(counts != floor(counts))
) stop("Missing or invalid counts.")
if (any(
  audit_data$recorded_count_total !=
  audit_data$renewed + audit_data$insurer_nonrenewed +
  audit_data$insured_nonrenewed
)) stop("T does not equal R + I + U.")

pct <- function(numerator, denominator) {
  value <- 100 * numerator / denominator
  ifelse(denominator > 0 & is.finite(value), value, NA_real_)
}

# Official 2020 Census reference, verified on the Census directory.
gaz_url <- paste0(
  "https://www2.census.gov/geo/docs/maps-data/data/",
  "gazetteer/2020_Gazetteer/2020_Gaz_zcta_national.zip"
)
gaz_path <- file.path(raw_folder, "2020_Gaz_zcta_national.zip")
if (!file.exists(gaz_path)) {
  tryCatch(
    download.file(gaz_url, gaz_path, mode = "wb"),
    error = function(e) {
      if (file.exists(gaz_path)) unlink(gaz_path)
      stop("Census download failed. Check your internet connection.")
    }
  )
}
members <- unzip(gaz_path, list = TRUE)$Name
member <- members[grepl("zcta.*[.]txt$", members, ignore.case = TRUE)]
if (length(member) != 1L) {
  stop("Could not identify one ZCTA text file in the Census archive.")
}
gaz <- read.delim(
  unz(gaz_path, member),
  colClasses = "character",
  check.names = FALSE,
  strip.white = TRUE
)
names(gaz) <- sub("^\ufeff", "", trimws(names(gaz)))
if (!"GEOID" %in% names(gaz)) stop("Expected Census GEOID column not found.")
zcta_codes <- trimws(gaz$GEOID)
if (
  anyNA(zcta_codes) ||
  any(!grepl("^[0-9]{5}$", zcta_codes)) ||
  anyDuplicated(zcta_codes) > 0
) stop("Review the Census reference identifiers.")

audit_data <- audit_data %>%
  mutate(zcta2020_match = zip %in% zcta_codes)

audit_summary <- audit_data %>%
  group_by(zcta2020_match) %>%
  summarise(
    unique_zip_labels = n_distinct(zip),
    zip_year_records = n(),
    federal_visible_records = sum(federal_visible),
    recorded_total = sum(recorded_count_total),
    .groups = "drop"
  ) %>%
  mutate(
    record_share_pct = pct(zip_year_records, sum(zip_year_records)),
    recorded_count_share_pct = pct(recorded_total, sum(recorded_total))
  )

# Reference county labels checked against the official
# California Volunteers lookup. This is not a historical
# USPS ZIP-type classification or an insured-property crosswalk.
county_reference <- data.frame(
  zip = c(
    "90017", "90058", "91948", "92066", "92258", "92327",
    "93016", "93201", "93447", "95554", "95656", "95724", "96086"
  ),
  reference_county = c(
    "Los Angeles", "Los Angeles", "San Diego", "San Diego",
    "Riverside", "San Bernardino", "Ventura", "Tulare",
    "San Luis Obispo", "Humboldt", "El Dorado", "Nevada", "Siskiyou"
  ),
  stringsAsFactors = FALSE
)
normalize_county <- function(x) {
  gsub("[^a-z]", "", tolower(trimws(x)))
}

rank_hotspots <- function(x) {
  x <- x %>% filter(recorded_count_total >= 100)
  if (!setequal(unique(x$year), 2018:2021)) {
    stop("A geographic sample has no eligible records in a study year.")
  }
  x %>%
    mutate(score = insurer_nonrenewed / recorded_count_total) %>%
    group_by(year) %>%
    mutate(
      target = ceiling(0.10 * n()),
      cutoff = sort(score, decreasing = TRUE)[first(target)],
      hotspot = score >= cutoff
    ) %>%
    ungroup()
}

original_ranked <- rank_hotspots(audit_data)
mapped_ranked <- rank_hotspots(
  audit_data %>% filter(zcta2020_match)
)

primary_omitted <- original_ranked %>%
  filter(hotspot, !federal_usable) %>%
  left_join(county_reference, by = "zip") %>%
  mutate(
    county_reference_match = (
      !is.na(county) & !is.na(reference_county) &
        normalize_county(county) == normalize_county(reference_county)
    )
  )
if (
  nrow(primary_omitted) != 24 ||
  n_distinct(primary_omitted$zip) != 13 ||
  !setequal(unique(primary_omitted$zip), county_reference$zip)
) {
  stop("The main omitted hotspot set differs from the reviewed pilot. Investigate before continuing.")
}

omitted_zip_audit <- primary_omitted %>%
  group_by(zip) %>%
  summarise(
    years = paste(sort(unique(year)), collapse = ", "),
    county = paste(sort(unique(county)), collapse = "; "),
    reference_county = first(reference_county),
    county_reference_match = all(county_reference_match),
    zcta2020_match = first(zcta2020_match),
    minimum_T = min(recorded_count_total),
    maximum_T = max(recorded_count_total),
    .groups = "drop"
  )

summarize_hotspots <- function(x, label) {
  x %>%
    group_by(year) %>%
    summarise(
      sample = label,
      eligible_records = n(),
      hotspots = sum(hotspot),
      omitted_hotspots = sum(hotspot & !federal_usable),
      hotspot_T = sum(recorded_count_total[hotspot]),
      omitted_hotspot_T = sum(
        recorded_count_total[hotspot & !federal_usable]
      ),
      .groups = "drop"
    ) %>%
    mutate(
      hotspot_omission_pct = pct(omitted_hotspots, hotspots),
      hotspot_count_omission_pct = pct(omitted_hotspot_T, hotspot_T)
    )
}
geography_hotspot_sensitivity <- bind_rows(
  summarize_hotspots(original_ranked, "Original ZIP labels"),
  summarize_hotspots(mapped_ranked, "Matching 2020 ZCTA labels")
)

definition_agreement <- function(x, label) {
  x %>%
    mutate(
      combined_score = (
        insurer_nonrenewed + insured_nonrenewed
      ) / recorded_count_total
    ) %>%
    group_by(year) %>%
    mutate(
      combined_cutoff = sort(
        combined_score, decreasing = TRUE
      )[first(target)],
      combined_hotspot = combined_score >= combined_cutoff
    ) %>%
    summarise(
      sample = label,
      insurer_hotspots = sum(hotspot),
      combined_hotspots = sum(combined_hotspot),
      shared = sum(hotspot & combined_hotspot),
      union = sum(hotspot | combined_hotspot),
      .groups = "drop"
    ) %>%
    mutate(
      insurer_hotspot_retention_pct = pct(shared, insurer_hotspots),
      jaccard_pct = pct(shared, union)
    )
}
geography_definition_sensitivity <- bind_rows(
  definition_agreement(original_ranked, "Original ZIP labels"),
  definition_agreement(mapped_ranked, "Matching 2020 ZCTA labels")
)

write.csv(audit_summary,
          file.path(output_folder, "submission_geography_summary.csv"),
          row.names = FALSE)
write.csv(omitted_zip_audit,
          file.path(output_folder, "submission_omitted_zip_audit.csv"),
          row.names = FALSE, na = "")
write.csv(geography_hotspot_sensitivity,
          file.path(output_folder, "submission_geography_hotspot_sensitivity.csv"),
          row.names = FALSE, na = "")
write.csv(geography_definition_sensitivity,
          file.path(output_folder, "submission_geography_definition_sensitivity.csv"),
          row.names = FALSE, na = "")

# Source and software fingerprints for reproducibility.
manifest <- data.frame(
  source = "2020 Census ZCTA Gazetteer",
  source_url = gaz_url,
  local_filename = basename(gaz_path),
  bytes = file.info(gaz_path)$size,
  md5 = unname(tools::md5sum(gaz_path)),
  checked_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
)
write.csv(manifest,
          file.path(output_folder, "submission_geography_reference_manifest.csv"),
          row.names = FALSE)
writeLines(capture.output(sessionInfo()),
           file.path(output_folder, "submission_session_info.txt"))

# Inventory saved scripts; this does not execute or publish them.
script_paths <- list.files(
  project_path,
  pattern = "[.](R|Rmd|qmd)$",
  full.names = TRUE, recursive = TRUE, ignore.case = TRUE
)
script_paths <- script_paths[
  !grepl(
    "/(renv|packrat|data_raw|data_clean|outputs)/",
    gsub("\\", "/", script_paths, fixed = TRUE)
  )
]
root <- normalizePath(project_path, winslash = "/", mustWork = TRUE)
if (length(script_paths)) {
  script_inventory <- data.frame(
    relative_path = substring(
      normalizePath(script_paths, winslash = "/", mustWork = TRUE),
      nchar(root) + 2L
    ),
    bytes = file.info(script_paths)$size,
    md5 = unname(tools::md5sum(script_paths))
  )
} else {
  script_inventory <- data.frame(
    relative_path = character(),
    bytes = numeric(),
    md5 = character()
  )
}
write.csv(script_inventory,
          file.path(output_folder, "submission_script_inventory.csv"),
          row.names = FALSE)

cat("\nGEOGRAPHY SUMMARY\n")
print(as.data.frame(audit_summary), row.names = FALSE)
cat("\nOMITTED ZIP AUDIT\n")
print(as.data.frame(omitted_zip_audit), row.names = FALSE)
cat("\nGEOGRAPHY HOTSPOT SENSITIVITY\n")
print(as.data.frame(geography_hotspot_sensitivity), row.names = FALSE)
cat("\nGEOGRAPHY DEFINITION SENSITIVITY\n")
print(as.data.frame(geography_definition_sensitivity), row.names = FALSE)
cat("\nSAVED SCRIPT INVENTORY\n")
print(script_inventory, row.names = FALSE)
cat("\nAudit outputs saved. Original analysis files were not overwritten.\n")
cat("Census membership does not certify postal validity or property location.\n")
cat("The full-run verification status is recorded separately.\n")
