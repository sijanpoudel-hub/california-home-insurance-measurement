# Official sources and input requirements

Keep original inputs unchanged and retain the workbook definition and disclaimer sheets. The initial public archive does not distribute the workbooks or derived RDS datasets.

| Input | Study vintage and scope | Source |
|---|---|---|
| California ZIP workbook | 2015–2021; main analysis uses 2018–2021 | [California Department of Insurance data portal](https://www.insurance.ca.gov/01-consumers/200-wrr/DataAnalysisOnWildfiresAndInsurance.cfm) |
| Treasury metrics workbook | 2018–2022; main match uses 2018–2021 | [Official Treasury workbook](https://home.treasury.gov/system/files/311/Supporting_Underlying_Metrics_and_Disclaimer_for_Analyses_of_US_Homeowners_Insurance_Markets_2018-2022.xlsx) |
| County classification | Fixed 2013 Rural–Urban Continuum Codes | [USDA official data page](https://ers.usda.gov/data-products/rural-urban-continuum-codes) |
| Census ZCTA labels | Fixed 2020 national Gazetteer | [Official ZIP archive](https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_zcta_national.zip) |
| County reference for 13 omitted ZIP labels | Public lookup used for label consistency | [California Volunteers](https://www.californiavolunteers.ca.gov/look-up-your-county-by-zip-code/) |

## Original workbook filenames

The author used these local filenames:

- `California ZIP data for 2015–2021.xlsx`
- `Treasury homeowners insurance metrics for 2018–2022.xlsx`

The California sheet is `New Renew NonRenew`. The Treasury data sheet is `Supporting Underlying Metrics`; retain `Metric Definitions` and `Disclaimer & Background`.

The original scripts' input paths still need to be reviewed. Merely placing workbooks in this folder does not yet establish that the full analysis will run.

The portable geography audit caches `2020_Gaz_zcta_national.zip` in this folder and writes its size and MD5 fingerprint to the output manifest.

## Definition references

- [CDI December 2022 fact sheet](https://www.insurance.ca.gov/01-consumers/200-wrr/upload/CDI-Fact-Sheet-Residential-Insurance-Market-Policy-Count-Data-December-2022.pdf): retain the cancellations and reporting-classification qualifications.
- [CDI county analysis for 2015–2021](https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Insurance-Policy-Analysis-by-County-2015-to-2021-2.pdf): source-vintage reconciliation reference.
- [Treasury report](https://home.treasury.gov/system/files/311/Analyses_of_US_Homeowners_Insurance_Markets_2018-2022_Climate-Related_Risks_and_Other_Factors_0.pdf): collection scope and definitions.
- [Census ZCTA guidance](https://www.census.gov/programs-surveys/geography/guidance/geo-areas/zctas.html): a postal ZIP does not necessarily have a corresponding ZCTA.

## Input manifest still required

For each frozen input, record its exact filename, agency, source URL, vintage, known acquisition date, byte size and file hash. Actual workbook fingerprints have not yet been supplied to this archive; none are inferred here. Cite and observe the source agencies' terms separately from the research code.
