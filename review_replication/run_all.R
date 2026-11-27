# Run with Rscript --vanilla run_all.R from a downloaded repository.
# Original scripts are evaluated in separate environments, in order.
run_california_analysis <- function() {
  root <- Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd())
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  if (!file.exists(file.path(root, "R", "config.R"))) {
    stop("Open R in the downloaded repository folder, then run run_all.R.")
  }
  needed <- c("readxl", "dplyr")
  missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop('Install dependencies first: install.packages(c("readxl", "dplyr"))')
  }
  previous_wd <- getwd()
  previous_root <- Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = NA_character_)
  on.exit({
    setwd(previous_wd)
    if (is.na(previous_root)) Sys.unsetenv("CA_INSURANCE_PROJECT_ROOT")
    else Sys.setenv(CA_INSURANCE_PROJECT_ROOT = previous_root)
  }, add = TRUE)
  setwd(root)
  Sys.setenv(CA_INSURANCE_PROJECT_ROOT = root)
  options(timeout = max(300, getOption("timeout")), repos = c(CRAN = "https://cloud.r-project.org"))
  dir.create("outputs", showWarnings = FALSE)
  scripts <- c(
    "01_clean_california.R",
    "02_calculate_measures.R",
    "03_match_treasury.R",
    "04_statewide_comparisons.R",
    "05_hotspot_sensitivity.R",
    "06_definition_comparisons.R",
    "07_geography_audit.R",
    "R/verify_outputs.R"
  )
  # Parse every required script before writing analytical outputs.
  for (script in c("R/config.R", scripts)) {
    if (!file.exists(script) || file.info(script)$size == 0) {
      stop("Missing or empty script: ", script)
    }
    parse(file = script, encoding = "UTF-8")
  }
  run_status <- data.frame(script = scripts, status = "Not run")
  status_path <- file.path("outputs", "pipeline_status.csv")
  write.csv(run_status, status_path, row.names = FALSE)
  for (i in seq_along(scripts)) {
    cat("\nRUNNING:", scripts[i], "\n")
    run_status$status[i] <- "Running"
    write.csv(run_status, status_path, row.names = FALSE)
    tryCatch(
      source(scripts[i], local = new.env(parent = globalenv()), encoding = "UTF-8"),
      error = function(e) {
        run_status$status[i] <<- paste("Failed:", conditionMessage(e))
        write.csv(run_status, status_path, row.names = FALSE)
        stop(conditionMessage(e), call. = FALSE)
      }
    )
    run_status$status[i] <- "Passed"
    write.csv(run_status, status_path, row.names = FALSE)
  }
  source("R/config.R", local = TRUE, encoding = "UTF-8")
  input_paths <- c(
    ca_california_path, ca_treasury_path,
    file.path(root, "data_raw", "usda_rucc2013.xls"),
    file.path(root, "data_raw", "2020_Gaz_zcta_national.zip")
  )
  if (any(!file.exists(input_paths))) stop("A required input is missing from the final manifest.")
  urls <- c(
    "https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Property-Voluntary-Market-New-Renew-NonRenew-by-ZIP-2015-2021.xlsx",
    "https://home.treasury.gov/system/files/311/Supporting_Underlying_Metrics_and_Disclaimer_for_Analyses_of_US_Homeowners_Insurance_Markets_2018-2022.xlsx",
    "https://ers.usda.gov/media/5769/2013-rural-urban-continuum-codes.xls?v=91459",
    "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_zcta_national.zip"
  )
  manifest <- data.frame(
    filename = basename(input_paths),
    source_url = urls,
    bytes = file.info(input_paths)$size,
    md5 = unname(tools::md5sum(input_paths)),
    observed_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
  write.csv(manifest, "outputs/input_manifest.csv", row.names = FALSE)
  writeLines(capture.output(sessionInfo()), "outputs/full_run_session_info.txt")
  cat("\nFULL ANALYSIS AND REPORTED-RESULT CHECKS PASSED.\n")
  cat("Exact inputs and software are recorded in outputs/.\n")
}
run_california_analysis()
