# Download original public agency inputs without altering valid existing files.
source(file.path(Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd()),
                 "R", "config.R"), local = TRUE, encoding = "UTF-8")
if (!requireNamespace("readxl", quietly = TRUE)) stop("Install readxl before downloading inputs.")
options(timeout = max(300, getOption("timeout")))
dir.create(file.path(ca_project_root, "data_raw"), showWarnings = FALSE)
dir.create(file.path(ca_project_root, "outputs"), showWarnings = FALSE)
sources <- data.frame(
  filename = c(
    "California ZIP data for 2015–2021.xlsx",
    "Treasury homeowners insurance metrics for 2018–2022.xlsx",
    "usda_rucc2013.xls",
    "2020_Gaz_zcta_national.zip"
  ),
  source_url = c(
    "https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Property-Voluntary-Market-New-Renew-NonRenew-by-ZIP-2015-2021.xlsx",
    "https://home.treasury.gov/system/files/311/Supporting_Underlying_Metrics_and_Disclaimer_for_Analyses_of_US_Homeowners_Insurance_Markets_2018-2022.xlsx",
    "https://ers.usda.gov/media/5769/2013-rural-urban-continuum-codes.xls?v=91459",
    "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_zcta_national.zip"
  ),
  stringsAsFactors = FALSE
)
valid_input <- function(path, filename) {
  if (!file.exists(path) || file.info(path)$size == 0) return(FALSE)
  tryCatch({
    if (grepl("[.]zip$", filename)) {
      any(grepl("zcta.*[.]txt$", unzip(path, list = TRUE)$Name, ignore.case = TRUE))
    } else {
      sheets <- readxl::excel_sheets(path)
      if (filename == sources$filename[1]) "New Renew NonRenew" %in% sheets
      else if (filename == sources$filename[2]) "Supporting Underlying Metrics" %in% sheets
      else length(sheets) > 0
    }
  }, error = function(e) FALSE)
}
download_log <- list()
for (i in seq_len(nrow(sources))) {
  filename <- sources$filename[i]
  target <- if (i == 1L) ca_california_path else if (i == 2L) ca_treasury_path else
    file.path(ca_project_root, "data_raw", filename)
  if (valid_input(target, filename)) {
    action <- "Reused existing valid file; acquisition date not inferred"
  } else {
    if (file.exists(target)) {
      stop("An existing input is unreadable; preserve it and investigate: ", target)
    }
    temporary <- tempfile("agency-input-", tmpdir = dirname(target))
    ok <- FALSE
    for (attempt in 1:3) {
      cat("Downloading", filename, "(attempt", attempt, ")\n")
      result <- tryCatch(
        download.file(sources$source_url[i], temporary, mode = "wb"),
        error = function(e) { message(conditionMessage(e)); 1L }
      )
      if (identical(as.integer(result), 0L) && valid_input(temporary, filename)) {
        ok <- TRUE
        break
      }
    }
    if (!ok) {
      unlink(temporary)
      stop("Could not obtain a valid agency input: ", filename)
    }
    if (!file.rename(temporary, target)) stop("Could not save downloaded input: ", filename)
    action <- "Downloaded from official source in this run"
  }
  download_log[[i]] <- data.frame(
    filename = filename, source_url = sources$source_url[i], action = action,
    observed_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    bytes = file.info(target)$size, md5 = unname(tools::md5sum(target))
  )
}
write.csv(do.call(rbind, download_log),
          file.path(ca_project_root, "outputs", "input_acquisition_log.csv"),
          row.names = FALSE)
