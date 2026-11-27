# Repository locations; run from this repository or set CA_INSURANCE_PROJECT_ROOT.
source(
  file.path(Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd()),
            "R", "config.R"),
  local = TRUE, encoding = "UTF-8"
)

# ============================================================
# STEP 10: ADDITIONAL CHECKS AND CONTRIBUTION ASSESSMENT
#
# Produces:
# 1. Pooled statewide measures.
# 2. Pooled ZIP-level hotspot omission.
# 3. Hotspot agreement between the two definitions.
#
# Important:
# - Pool counts first, then divide.
# - Never replace an absent year with zero.
# - Keep the annual T >= 100, top-10% analysis as primary.
# - Label these additional comparisons transparently.
# ============================================================


# ------------------------------------------------------------
# 1. Load package and dataset
# ------------------------------------------------------------

if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr")
}

library(dplyr)

project_path <- ca_project_root

clean_folder <- file.path(project_path, "data_clean")
output_folder <- file.path(project_path, "outputs")

matched_path <- file.path(
  clean_folder,
  "california_federal_matched_2018_2021.rds"
)

if (!file.exists(matched_path)) {
  stop("The Step 7 matched dataset was not found.")
}

dir.create(
  output_folder,
  recursive = TRUE,
  showWarnings = FALSE
)

step10_data <- readRDS(matched_path)

required <- c(
  "zip",
  "year",
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed",
  "recorded_count_total",
  "federal_visible",
  "federal_usable"
)

if (!all(required %in% names(step10_data))) {
  stop("Required columns are missing.")
}

if (
  nrow(step10_data) == 0 ||
  anyNA(step10_data$year) ||
  !setequal(unique(step10_data$year), 2018:2021)
) {
  stop("Check the dataset and reporting years.")
}

if (
  anyNA(step10_data$zip) ||
  anyDuplicated(step10_data[c("zip", "year")]) > 0
) {
  stop("Missing ZIP codes or duplicate ZIP-year records were found.")
}

for (flag in c("federal_visible", "federal_usable")) {
  
  if (
    !is.logical(step10_data[[flag]]) ||
    anyNA(step10_data[[flag]])
  ) {
    stop("Federal flags must be nonmissing logical values.")
  }
}

if (
  any(
    step10_data$federal_usable &
    !step10_data$federal_visible
  )
) {
  stop("A usable federal value must also be visible.")
}

count_fields <- c(
  "renewed",
  "insurer_nonrenewed",
  "insured_nonrenewed",
  "recorded_count_total"
)

if (
  !all(
    vapply(
      step10_data[count_fields],
      is.numeric,
      logical(1)
    )
  )
) {
  stop("Count variables must be numeric.")
}

count_matrix <- as.matrix(
  step10_data[count_fields]
)

if (
  any(!is.finite(count_matrix)) ||
  any(count_matrix < 0) ||
  any(count_matrix != floor(count_matrix))
) {
  stop("Missing or invalid counts were found.")
}

if (
  any(
    step10_data$recorded_count_total !=
    step10_data$renewed +
    step10_data$insurer_nonrenewed +
    step10_data$insured_nonrenewed
  )
) {
  stop("The denominator does not equal R + I + U.")
}


# ------------------------------------------------------------
# 2. Helpers and analysis settings
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
        matches("_pct$|_pp$|_correlation$"),
        ~ round(.x, 6)
      )
    ) %>%
    as.data.frame()
}

minimum_annual_count <- 100
top_fraction <- 0.10


# ------------------------------------------------------------
# 3. Pooled statewide measures
#
# Pool all four years by adding counts.
# This is not an average of annual or ZIP-level shares.
#
# The visible population uses availability separately
# for each ZIP-year, consistently with Step 8.
# ------------------------------------------------------------

summarize_population <- function(x, population_label) {
  
  x %>%
    summarise(
      population = population_label,
      zip_year_records = n(),
      renewed = sum(renewed),
      insurer_count = sum(insurer_nonrenewed),
      policyholder_count = sum(insured_nonrenewed),
      recorded_total = sum(recorded_count_total)
    ) %>%
    mutate(
      insurer_share_pct = safe_percent(
        insurer_count,
        recorded_total
      ),
      
      combined_share_pct = safe_percent(
        insurer_count + policyholder_count,
        recorded_total
      )
    )
}

step10_pooled_statewide <- bind_rows(
  summarize_population(
    step10_data,
    "All California ZIP-years"
  ),
  
  summarize_population(
    step10_data %>%
      filter(federal_visible),
    "Federally visible ZIP-years"
  )
)

pooled_selection_difference_pp <- (
  step10_pooled_statewide$insurer_share_pct[2] -
    step10_pooled_statewide$insurer_share_pct[1]
)

cat("\n1. POOLED STATEWIDE RESULTS\n")

print(
  display_table(step10_pooled_statewide),
  row.names = FALSE
)

cat(
  "\nVisible minus all, insurer share:",
  sprintf("%.6f", pooled_selection_difference_pp),
  "percentage points\n"
)


# ------------------------------------------------------------
# 4. Create pooled ZIP-level counts
#
# For pooled local ranking, require:
# - a record in all four study years;
# - T >= 100 in EACH year.
#
# This defines a stable comparison sample.
# It is an additional sample restriction, so report it.
# Missing years are not filled with zeros.
# ------------------------------------------------------------

pooled_zip <- step10_data %>%
  group_by(zip) %>%
  summarise(
    years_observed = n_distinct(year),
    
    years_meeting_minimum = sum(
      recorded_count_total >= minimum_annual_count
    ),
    
    usable_federal_years =
      sum(federal_usable),
    
    renewed =
      sum(renewed),
    
    insurer_count =
      sum(insurer_nonrenewed),
    
    policyholder_count =
      sum(insured_nonrenewed),
    
    recorded_total =
      sum(recorded_count_total),
    
    .groups = "drop"
  ) %>%
  mutate(
    complete_four_years =
      years_observed == 4,
    
    eligible_pooled_sample = (
      complete_four_years &
        years_meeting_minimum == 4
    ),
    
    complete_federal_history =
      usable_federal_years == 4,
    
    pooled_insurer_share = ifelse(
      recorded_total > 0,
      insurer_count / recorded_total,
      NA_real_
    )
  )

pooled_sample_summary <- data.frame(
  sample = c(
    "All observed ZIP codes",
    "Observed in all four years",
    "All four years and annual T >= 100"
  ),
  
  zip_codes = c(
    nrow(pooled_zip),
    
    sum(pooled_zip$complete_four_years),
    
    sum(pooled_zip$eligible_pooled_sample)
  )
)

cat("\nPOOLED ZIP SAMPLE COUNTS\n")

print(
  pooled_sample_summary,
  row.names = FALSE
)


# ------------------------------------------------------------
# 5. Identify pooled hotspots
#
# Rank pooled I / pooled T.
# Select the top 10%, including ties.
#
# Federal omission here means that at least one of the
# four annual federal values is not usable.
# ------------------------------------------------------------

pooled_eligible <- pooled_zip %>%
  filter(eligible_pooled_sample)

if (nrow(pooled_eligible) == 0) {
  stop("No ZIP codes meet the pooled local eligibility rule.")
}

pooled_target <- ceiling(
  top_fraction * nrow(pooled_eligible)
)

pooled_cutoff <- sort(
  pooled_eligible$pooled_insurer_share,
  decreasing = TRUE
)[pooled_target]

pooled_eligible <- pooled_eligible %>%
  mutate(
    pooled_hotspot =
      pooled_insurer_share >= pooled_cutoff
  )

step10_pooled_hotspots <- pooled_eligible %>%
  summarise(
    eligible_zip_codes = n(),
    
    target_hotspots = pooled_target,
    
    cutoff_share_pct =
      100 * pooled_cutoff,
    
    hotspots =
      sum(pooled_hotspot),
    
    hotspots_without_complete_federal_history =
      sum(
        pooled_hotspot &
          !complete_federal_history
      ),
    
    hotspot_recorded_total =
      sum(recorded_total[pooled_hotspot]),
    
    omitted_hotspot_recorded_total =
      sum(
        recorded_total[
          pooled_hotspot &
            !complete_federal_history
        ]
      )
  ) %>%
  mutate(
    hotspot_omission_pct = safe_percent(
      hotspots_without_complete_federal_history,
      hotspots
    ),
    
    hotspot_count_omission_pct = safe_percent(
      omitted_hotspot_recorded_total,
      hotspot_recorded_total
    )
  )

cat("\n2. POOLED ZIP HOTSPOT RESULTS\n")

print(
  display_table(step10_pooled_hotspots),
  row.names = FALSE
)


# ------------------------------------------------------------
# 6. Compare hotspot definitions on identical annual records
#
# Both definitions use:
# - the same ZIP-year records;
# - T >= 100;
# - the same denominator T;
# - annual top-10% selection including ties.
#
# Definition A: I / T
# Definition B: (I + U) / T
# ------------------------------------------------------------

definition_ranked <- step10_data %>%
  filter(
    recorded_count_total >= minimum_annual_count
  ) %>%
  mutate(
    insurer_share_calc =
      insurer_nonrenewed / recorded_count_total,
    
    combined_share_calc = (
      insurer_nonrenewed +
        insured_nonrenewed
    ) / recorded_count_total
  )

if (
  !setequal(
    unique(definition_ranked$year),
    2018:2021
  )
) {
  stop("A year has no eligible records for definition comparison.")
}

definition_ranked <- definition_ranked %>%
  group_by(year) %>%
  mutate(
    target_hotspots =
      ceiling(top_fraction * n()),
    
    insurer_cutoff = sort(
      insurer_share_calc,
      decreasing = TRUE
    )[first(target_hotspots)],
    
    combined_cutoff = sort(
      combined_share_calc,
      decreasing = TRUE
    )[first(target_hotspots)],
    
    insurer_hotspot =
      insurer_share_calc >= insurer_cutoff,
    
    combined_hotspot =
      combined_share_calc >= combined_cutoff
  ) %>%
  ungroup()

step10_definition_hotspots <- definition_ranked %>%
  group_by(year) %>%
  summarise(
    eligible_records = n(),
    
    insurer_hotspots =
      sum(insurer_hotspot),
    
    combined_hotspots =
      sum(combined_hotspot),
    
    shared_hotspots =
      sum(insurer_hotspot & combined_hotspot),
    
    insurer_only_hotspots =
      sum(insurer_hotspot & !combined_hotspot),
    
    combined_only_hotspots =
      sum(!insurer_hotspot & combined_hotspot),
    
    union_hotspots =
      sum(insurer_hotspot | combined_hotspot),
    
    spearman_correlation = if (
      n_distinct(insurer_share_calc) > 1 &&
      n_distinct(combined_share_calc) > 1
    ) {
      cor(
        insurer_share_calc,
        combined_share_calc,
        method = "spearman"
      )
    } else {
      NA_real_
    },
    
    .groups = "drop"
  ) %>%
  mutate(
    insurer_hotspot_retention_pct = safe_percent(
      shared_hotspots,
      insurer_hotspots
    ),
    
    hotspot_jaccard_pct = safe_percent(
      shared_hotspots,
      union_hotspots
    )
  )

cat("\n3. HOTSPOT AGREEMENT BETWEEN DEFINITIONS\n")

print(
  display_table(step10_definition_hotspots),
  row.names = FALSE
)


# ------------------------------------------------------------
# 7. Save outputs
# ------------------------------------------------------------

write.csv(
  step10_pooled_statewide,
  file.path(
    output_folder,
    "step10_pooled_statewide.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  pooled_sample_summary,
  file.path(
    output_folder,
    "step10_pooled_sample_counts.csv"
  ),
  row.names = FALSE
)

write.csv(
  step10_pooled_hotspots,
  file.path(
    output_folder,
    "step10_pooled_hotspot_summary.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  pooled_eligible %>%
    filter(pooled_hotspot) %>%
    arrange(desc(pooled_insurer_share), zip),
  file.path(
    output_folder,
    "step10_pooled_hotspot_list.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  step10_definition_hotspots,
  file.path(
    output_folder,
    "step10_definition_hotspot_comparison.csv"
  ),
  row.names = FALSE,
  na = ""
)

write.csv(
  definition_ranked %>%
    filter(insurer_hotspot != combined_hotspot),
  file.path(
    output_folder,
    "step10_definition_disagreement_records.csv"
  ),
  row.names = FALSE,
  na = ""
)


# ------------------------------------------------------------
# 8. Save method notes
# ------------------------------------------------------------

method_notes <- c(
  "STEP 10: ADDITIONAL COMPARISONS",
  "",
  "The annual T >= 100, top-10% analysis remains primary.",
  "Threshold sensitivity results are reported separately.",
  "",
  "Pooled statewide shares sum counts before dividing.",
  "Federal visibility is applied at the ZIP-year level.",
  "",
  "Pooled local analysis requires four observed years",
  "and T >= 100 in each year.",
  "This additional eligibility rule was specified",
  "after inspection of the initial pilot results.",
  "Absent observations are not replaced with zeros.",
  "",
  "Pooled hotspot omission means incomplete usable",
  "federal information across the four study years.",
  "This differs from single-year omission.",
  "",
  "Definition comparisons use identical annual samples.",
  "Each definition retains ties at its own cutoff.",
  "Retention is shared hotspots / insurer hotspots.",
  "Jaccard is shared hotspots / union of hotspot sets.",
  "Spearman measures agreement of the two rankings.",
  "",
  "These comparisons are descriptive.",
  "They do not establish which definition is correct",
  "for every research question.",
  "",
  "Reported California termination counts include",
  "nonrenewals and cancellations.",
  "The 2020 nonpayment classification change remains",
  "a limitation for comparisons across years.",
  "",
  "Postal-geography validation of the omitted ZIPs",
  "remains incomplete.",
  "Do not label every ZIP a residential community.",
  "",
  "Do not describe the entire project as preregistered.",
  paste("Run date:", Sys.Date())
)

writeLines(
  method_notes,
  file.path(
    output_folder,
    "step10_methods_notes.txt"
  )
)

cat("\nSTEP 10 ADDITIONAL COMPARISONS SAVED\n")
cat("Output folder:", output_folder, "\n")




cat("\n1. POOLED ZIP SAMPLE COUNTS\n")

print(
  as.data.frame(pooled_sample_summary),
  row.names = FALSE
)


cat("\n2. POOLED ZIP HOTSPOT RESULTS\n")

print(
  display_table(step10_pooled_hotspots),
  row.names = FALSE
)


cat("\n3. HOTSPOT AGREEMENT BETWEEN DEFINITIONS\n")

print(
  display_table(step10_definition_hotspots),
  row.names = FALSE
)
