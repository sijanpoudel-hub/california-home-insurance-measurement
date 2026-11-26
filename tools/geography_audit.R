# Compatibility entry point. The reviewed audit is maintained in one place.
source(
  file.path(Sys.getenv("CA_INSURANCE_PROJECT_ROOT", unset = getwd()),
            "11_submission_audit.R"),
  local = TRUE, encoding = "UTF-8"
)
