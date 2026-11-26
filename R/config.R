# Shared locations. Original workbook names and analytical rules are preserved.
ca_project_root <- normalizePath(
  Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd()),
  winslash = "/", mustWork = TRUE
)
ca_input_file <- function(filename, override_variable) {
  override <- Sys.getenv(override_variable, unset = "")
  if (nzchar(override)) {
    if (!file.exists(override)) stop("Input override not found: ", override_variable)
    return(normalizePath(override, winslash = "/", mustWork = TRUE))
  }
  candidates <- c(
    file.path(ca_project_root, "data_raw", filename),
    file.path(ca_project_root, filename)
  )
  found <- candidates[file.exists(candidates)]
  if (length(found) > 1L &&
      length(unique(unname(tools::md5sum(found)))) > 1L) {
    stop("Different copies of ", filename,
         " exist in the root and data_raw. Select one with ",
         override_variable, ".")
  }
  if (length(found)) found[1] else candidates[1]
}
ca_california_path <- ca_input_file(
  "California ZIP data for 2015–2021.xlsx", "CA_INSURANCE_CALIFORNIA_FILE"
)
ca_treasury_path <- ca_input_file(
  "Treasury homeowners insurance metrics for 2018–2022.xlsx",
  "CA_INSURANCE_TREASURY_FILE"
)
