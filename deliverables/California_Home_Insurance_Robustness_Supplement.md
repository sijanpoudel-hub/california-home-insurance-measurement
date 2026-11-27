# Additional robustness checks and release reconciliation

## Purpose and interpretation

This supplement reports all added exploratory checks. The original T≥100/top-10% analysis remains primary. Every numerical table is generated from the saved code outputs. New-plus-renewed normalization is descriptive, not an at-risk cohort; county exclusions rerank the remaining sample. No missing count or measure is imputed as zero.

S1. Full definition sensitivity grid

| Year | Minimum T | Top fraction | Eligible | Insurer hotspots | Combined hotspots | Shared | Retention % | Jaccard % |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2018 | 50 | 0.050 | 1,639 | 82 | 82 | 30 | 36.585 | 22.388 |
| 2018 | 50 | 0.100 | 1,639 | 165 | 164 | 71 | 43.030 | 27.519 |
| 2018 | 50 | 0.200 | 1,639 | 329 | 329 | 155 | 47.112 | 30.815 |
| 2018 | 100 | 0.050 | 1,562 | 79 | 79 | 26 | 32.911 | 19.697 |
| 2018 | 100 | 0.100 | 1,562 | 157 | 157 | 62 | 39.490 | 24.603 |
| 2018 | 100 | 0.200 | 1,562 | 313 | 313 | 146 | 46.645 | 30.417 |
| 2018 | 200 | 0.050 | 1,441 | 73 | 73 | 20 | 27.397 | 15.873 |
| 2018 | 200 | 0.100 | 1,441 | 145 | 145 | 53 | 36.552 | 22.363 |
| 2018 | 200 | 0.200 | 1,441 | 289 | 289 | 138 | 47.751 | 31.364 |
| 2019 | 50 | 0.050 | 1,646 | 83 | 83 | 58 | 69.880 | 53.704 |
| 2019 | 50 | 0.100 | 1,646 | 165 | 165 | 125 | 75.758 | 60.976 |
| 2019 | 50 | 0.200 | 1,646 | 330 | 330 | 254 | 76.970 | 62.562 |
| 2019 | 100 | 0.050 | 1,563 | 79 | 79 | 62 | 78.481 | 64.583 |
| 2019 | 100 | 0.100 | 1,563 | 157 | 157 | 123 | 78.344 | 64.398 |
| 2019 | 100 | 0.200 | 1,563 | 313 | 313 | 241 | 76.997 | 62.597 |
| 2019 | 200 | 0.050 | 1,447 | 73 | 73 | 57 | 78.082 | 64.045 |
| 2019 | 200 | 0.100 | 1,447 | 145 | 145 | 112 | 77.241 | 62.921 |
| 2019 | 200 | 0.200 | 1,447 | 290 | 290 | 219 | 75.517 | 60.665 |
| 2020 | 50 | 0.050 | 1,643 | 83 | 83 | 57 | 68.675 | 52.294 |
| 2020 | 50 | 0.100 | 1,643 | 165 | 165 | 122 | 73.939 | 58.654 |
| 2020 | 50 | 0.200 | 1,643 | 329 | 329 | 244 | 74.164 | 58.937 |
| 2020 | 100 | 0.050 | 1,566 | 79 | 79 | 56 | 70.886 | 54.902 |
| 2020 | 100 | 0.100 | 1,566 | 157 | 157 | 116 | 73.885 | 58.586 |
| 2020 | 100 | 0.200 | 1,566 | 314 | 314 | 234 | 74.522 | 59.391 |
| 2020 | 200 | 0.050 | 1,450 | 73 | 73 | 55 | 75.342 | 60.440 |
| 2020 | 200 | 0.100 | 1,450 | 145 | 145 | 107 | 73.793 | 58.470 |
| 2020 | 200 | 0.200 | 1,450 | 290 | 290 | 216 | 74.483 | 59.341 |
| 2021 | 50 | 0.050 | 1,640 | 82 | 82 | 60 | 73.171 | 57.692 |
| 2021 | 50 | 0.100 | 1,640 | 164 | 164 | 104 | 63.415 | 46.429 |
| 2021 | 50 | 0.200 | 1,640 | 328 | 328 | 222 | 67.683 | 51.152 |
| 2021 | 100 | 0.050 | 1,567 | 79 | 79 | 58 | 73.418 | 58 |
| 2021 | 100 | 0.100 | 1,567 | 157 | 157 | 103 | 65.605 | 48.815 |
| 2021 | 100 | 0.200 | 1,567 | 314 | 314 | 216 | 68.790 | 52.427 |
| 2021 | 200 | 0.050 | 1,451 | 73 | 73 | 51 | 69.863 | 53.684 |
| 2021 | 200 | 0.100 | 1,451 | 146 | 146 | 97 | 66.438 | 49.744 |
| 2021 | 200 | 0.200 | 1,451 | 291 | 291 | 198 | 68.041 | 51.562 |

S2. All paired denominator comparisons

| Year | Comparison | Denominator or numerator | Top fraction | Eligible | Shared | Retention % | Jaccard % |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2018 | Insurer versus combined | T | 0.050 | 1,562 | 26 | 32.911 | 19.697 |
| 2018 | Insurer versus combined | D | 0.050 | 1,562 | 31 | 38.750 | 24.219 |
| 2018 | Denominator change | I | 0.050 | 1,562 | 75 | 94.937 | 89.286 |
| 2018 | Denominator change | C | 0.050 | 1,562 | 70 | 88.608 | 79.545 |
| 2018 | Insurer versus combined | T | 0.100 | 1,562 | 62 | 39.490 | 24.603 |
| 2018 | Insurer versus combined | D | 0.100 | 1,562 | 62 | 39.490 | 24.603 |
| 2018 | Denominator change | I | 0.100 | 1,562 | 152 | 96.815 | 93.827 |
| 2018 | Denominator change | C | 0.100 | 1,562 | 151 | 96.178 | 92.638 |
| 2018 | Insurer versus combined | T | 0.200 | 1,562 | 146 | 46.645 | 30.417 |
| 2018 | Insurer versus combined | D | 0.200 | 1,562 | 147 | 46.965 | 30.689 |
| 2018 | Denominator change | I | 0.200 | 1,562 | 307 | 98.083 | 96.238 |
| 2018 | Denominator change | C | 0.200 | 1,562 | 301 | 96.166 | 92.615 |
| 2019 | Insurer versus combined | T | 0.050 | 1,563 | 62 | 78.481 | 64.583 |
| 2019 | Insurer versus combined | D | 0.050 | 1,563 | 55 | 69.620 | 53.398 |
| 2019 | Denominator change | I | 0.050 | 1,563 | 74 | 93.671 | 88.095 |
| 2019 | Denominator change | C | 0.050 | 1,563 | 68 | 86.076 | 75.556 |
| 2019 | Insurer versus combined | T | 0.100 | 1,563 | 123 | 78.344 | 64.398 |
| 2019 | Insurer versus combined | D | 0.100 | 1,563 | 121 | 77.070 | 62.694 |
| 2019 | Denominator change | I | 0.100 | 1,563 | 151 | 96.178 | 92.638 |
| 2019 | Denominator change | C | 0.100 | 1,563 | 149 | 94.904 | 90.303 |
| 2019 | Insurer versus combined | T | 0.200 | 1,563 | 241 | 76.997 | 62.597 |
| 2019 | Insurer versus combined | D | 0.200 | 1,563 | 240 | 76.677 | 62.176 |
| 2019 | Denominator change | I | 0.200 | 1,563 | 309 | 98.722 | 97.476 |
| 2019 | Denominator change | C | 0.200 | 1,563 | 300 | 95.847 | 92.025 |
| 2020 | Insurer versus combined | T | 0.050 | 1,566 | 56 | 70.886 | 54.902 |
| 2020 | Insurer versus combined | D | 0.050 | 1,566 | 58 | 73.418 | 58 |
| 2020 | Denominator change | I | 0.050 | 1,566 | 77 | 97.468 | 95.062 |
| 2020 | Denominator change | C | 0.050 | 1,566 | 72 | 91.139 | 83.721 |
| 2020 | Insurer versus combined | T | 0.100 | 1,566 | 116 | 73.885 | 58.586 |
| 2020 | Insurer versus combined | D | 0.100 | 1,566 | 118 | 75.159 | 60.204 |
| 2020 | Denominator change | I | 0.100 | 1,566 | 153 | 97.452 | 95.031 |
| 2020 | Denominator change | C | 0.100 | 1,566 | 143 | 91.083 | 83.626 |
| 2020 | Insurer versus combined | T | 0.200 | 1,566 | 234 | 74.522 | 59.391 |
| 2020 | Insurer versus combined | D | 0.200 | 1,566 | 241 | 76.752 | 62.274 |
| 2020 | Denominator change | I | 0.200 | 1,566 | 310 | 98.726 | 97.484 |
| 2020 | Denominator change | C | 0.200 | 1,566 | 303 | 96.497 | 93.231 |
| 2021 | Insurer versus combined | T | 0.050 | 1,567 | 58 | 73.418 | 58 |
| 2021 | Insurer versus combined | D | 0.050 | 1,567 | 61 | 77.215 | 62.887 |
| 2021 | Denominator change | I | 0.050 | 1,567 | 74 | 93.671 | 88.095 |
| 2021 | Denominator change | C | 0.050 | 1,567 | 73 | 92.405 | 85.882 |
| 2021 | Insurer versus combined | T | 0.100 | 1,567 | 103 | 65.605 | 48.815 |
| 2021 | Insurer versus combined | D | 0.100 | 1,567 | 107 | 68.153 | 51.691 |
| 2021 | Denominator change | I | 0.100 | 1,567 | 154 | 98.089 | 96.250 |
| 2021 | Denominator change | C | 0.100 | 1,567 | 145 | 92.357 | 85.799 |
| 2021 | Insurer versus combined | T | 0.200 | 1,567 | 216 | 68.790 | 52.427 |
| 2021 | Insurer versus combined | D | 0.200 | 1,567 | 225 | 71.656 | 55.831 |
| 2021 | Denominator change | I | 0.200 | 1,567 | 302 | 96.178 | 92.638 |
| 2021 | Denominator change | C | 0.200 | 1,567 | 300 | 95.541 | 91.463 |

S3. Paired denominator sample accounting

| Year | T≥100 | D=0 excluded | Paired sample |
| --- | --- | --- | --- |
| 2018 | 1562 | 0 | 1562 |
| 2019 | 1563 | 0 | 1563 |
| 2020 | 1566 | 0 | 1566 |
| 2021 | 1567 | 0 | 1567 |

S4. Leave-one-county-out extremes

| Year | Metric | Minimum | Excluded county | Maximum | Excluded county |
| --- | --- | --- | --- | --- | --- |
| 2018 | selection_difference_pp | -0.002 | losangeles | -0.001 | humboldt |
| 2018 | gap_change_pp | -0.009 | tuolumne | -0.005 | humboldt |
| 2018 | retention_pct | 37.584 | sanbernardino | 42.308 | losangeles |
| 2018 | insurer_hotspot_omission_pct | 4.054 | sandiego | 5.405 | orange |
| 2019 | selection_difference_pp | -0.006 | losangeles | -0.005 | humboldt |
| 2019 | gap_change_pp | -0.005 | nevada | 0.024 | humboldt |
| 2019 | retention_pct | 76 | sanbernardino | 80 | riverside |
| 2019 | insurer_hotspot_omission_pct | 1.948 | humboldt | 3.077 | losangeles |
| 2020 | selection_difference_pp | -0.006 | losangeles | -0.003 | ventura |
| 2020 | gap_change_pp | 0.011 | nevada | 0.020 | humboldt |
| 2020 | retention_pct | 69.032 | eldorado | 78 | riverside |
| 2020 | insurer_hotspot_omission_pct | 3.226 | eldorado | 4.054 | orange |
| 2021 | selection_difference_pp | -0.002 | riverside | -0.001 | ventura |
| 2021 | gap_change_pp | -0.006 | tuolumne | 0.004 | mendocino |
| 2021 | retention_pct | 62.581 | eldorado | 66.154 | losangeles |
| 2021 | insurer_hotspot_omission_pct | 3.205 | nevada | 4.054 | orange |

The complete 236-row influence table is supplied as extended_leave_one_county_out.csv. NONE is the full-sample baseline, and named counties are omitted individually. Unknown-county rows remain in statewide counts.

S5. Release key coverage

| Year | Both | Earlier only | Later only |
| --- | --- | --- | --- |
| 2020 | 1996 | 158 | 117 |
| 2021 | 1955 | 171 | 86 |

S6. All overlapping-release comparisons

| Year | Sample | Metric | Earlier count | Later count | Difference | Change % | Changed common keys |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2020 | All records in each release | N | 1,057,402 | 1,007,422 | -49,980 | -4.727 | 1,618 |
| 2020 | All records in each release | R | 7,631,979 | 7,572,809 | -59,170 | -0.775 | 1,798 |
| 2020 | All records in each release | C | 992,227 | 898,064 | -94,163 | -9.490 | 1,742 |
| 2020 | Common ZIP-year keys | N | 1,057,382 | 1,007,406 | -49,976 | -4.726 | 1,618 |
| 2020 | Common ZIP-year keys | R | 7,631,096 | 7,572,611 | -58,485 | -0.766 | 1,798 |
| 2020 | Common ZIP-year keys | C | 991,951 | 898,062 | -93,889 | -9.465 | 1,742 |
| 2021 | All records in each release | N | 1,107,169 | 1,091,089 | -16,080 | -1.452 | 1,575 |
| 2021 | All records in each release | R | 7,621,326 | 7,514,564 | -106,762 | -1.401 | 1,777 |
| 2021 | All records in each release | C | 1,118,422 | 1,037,767 | -80,655 | -7.211 | 1,697 |
| 2021 | Common ZIP-year keys | N | 1,107,156 | 1,091,083 | -16,073 | -1.452 | 1,575 |
| 2021 | Common ZIP-year keys | R | 7,620,458 | 7,514,465 | -105,993 | -1.391 | 1,777 |
| 2021 | Common ZIP-year keys | C | 1,118,264 | 1,037,753 | -80,511 | -7.200 | 1,697 |

S7. Definition retention by reporting regime

| Reporting period | Minimum % | Maximum % |
| --- | --- | --- |
| 2018-2019 before clarification | 39.490 | 78.344 |
| 2020-2021 after clarification | 65.605 | 73.885 |

S8. Original hotspot-omission sensitivity grid

| Year | Minimum T | Top fraction | Hotspots omitted % | Hotspot T omitted % |
| --- | --- | --- | --- | --- |
| 2018 | 50 | 0.050 | 29.268 | 6.293 |
| 2019 | 50 | 0.050 | 10.843 | 0.572 |
| 2020 | 50 | 0.050 | 12.048 | 0.618 |
| 2021 | 50 | 0.050 | 7.317 | 0.359 |
| 2018 | 50 | 0.100 | 19.394 | 1.898 |
| 2019 | 50 | 0.100 | 14.545 | 0.642 |
| 2020 | 50 | 0.100 | 13.939 | 0.657 |
| 2021 | 50 | 0.100 | 7.317 | 0.354 |
| 2018 | 50 | 0.200 | 13.070 | 0.632 |
| 2019 | 50 | 0.200 | 12.424 | 0.483 |
| 2020 | 50 | 0.200 | 10.030 | 0.415 |
| 2021 | 50 | 0.200 | 7.622 | 0.239 |
| 2018 | 100 | 0.050 | 8.861 | 1.562 |
| 2019 | 100 | 0.050 | 1.266 | 0.087 |
| 2020 | 100 | 0.050 | 3.797 | 0.317 |
| 2021 | 100 | 0.050 | 3.797 | 0.231 |
| 2018 | 100 | 0.100 | 5.096 | 0.584 |
| 2019 | 100 | 0.100 | 2.548 | 0.156 |
| 2020 | 100 | 0.100 | 3.822 | 0.236 |
| 2021 | 100 | 0.100 | 3.822 | 0.223 |
| 2018 | 100 | 0.200 | 3.195 | 0.234 |
| 2019 | 100 | 0.200 | 2.236 | 0.112 |
| 2020 | 100 | 0.200 | 2.229 | 0.124 |
| 2021 | 100 | 0.200 | 2.548 | 0.108 |
| 2018 | 200 | 0.050 | 0 | 0 |
| 2019 | 200 | 0.050 | 0 | 0 |
| 2020 | 200 | 0.050 | 0 | 0 |
| 2021 | 200 | 0.050 | 0 | 0 |
| 2018 | 200 | 0.100 | 0 | 0 |
| 2019 | 200 | 0.100 | 0 | 0 |
| 2020 | 200 | 0.100 | 0 | 0 |
| 2021 | 200 | 0.100 | 0 | 0 |
| 2018 | 200 | 0.200 | 0.346 | 0.047 |
| 2019 | 200 | 0.200 | 0 | 0 |
| 2020 | 200 | 0.200 | 0 | 0 |
| 2021 | 200 | 0.200 | 0 | 0 |

S9. Original Census-label hotspot sensitivity

| Year | Sample | Eligible | Hotspots | Omitted | Omission % |
| --- | --- | --- | --- | --- | --- |
| 2018 | Original ZIP labels | 1,562 | 157 | 8 | 5.096 |
| 2019 | Original ZIP labels | 1,563 | 157 | 4 | 2.548 |
| 2020 | Original ZIP labels | 1,566 | 157 | 6 | 3.822 |
| 2021 | Original ZIP labels | 1,567 | 157 | 6 | 3.822 |
| 2018 | Matching 2020 ZCTA labels | 1,554 | 156 | 8 | 5.128 |
| 2019 | Matching 2020 ZCTA labels | 1,554 | 156 | 4 | 2.564 |
| 2020 | Matching 2020 ZCTA labels | 1,554 | 156 | 3 | 1.923 |
| 2021 | Matching 2020 ZCTA labels | 1,558 | 156 | 6 | 3.846 |

## Verification

Original R checks: 44. Supplementary checks: 14. Both reports must show all checks passed. Independent import checks verify extraction and calculations, not the accuracy of source insurer reporting.

California Department of Insurance. (2022a). Insurance Policy Count Data 2015–2021 [Fact sheet, December 2022]. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/CDI-Fact-Sheet-Residential-Insurance-Market-Policy-Count-Data-December-2022.pdf

California Department of Insurance. (2022b). Number of New, Renewed, and Non-Renewed Homeowners’ Policies: County Analysis 2015–2021. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Insurance-Policy-Analysis-by-County-2015-to-2021-2.pdf

California Department of Insurance. (n.d.-a). Residential Property Voluntary Market New, Renewed and Nonrenewed Policies by ZIP, 2015–2021 [Excel workbook]. Official data portal: https://www.insurance.ca.gov/01-consumers/200-wrr/DataAnalysisOnWildfiresAndInsurance.cfm

California Department of Insurance. (n.d.-b). Residential Insurance Voluntary Market New, Renewed and Nonrenewed Policies by ZIP, 2020–2023 [Excel workbook]. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Insurance-Voluntary-Market-New-Renew-NonRenew-by-ZIP-2020-2023.xlsx

California Department of Insurance. (n.d.-c). Summary on Residential Insurance Policies and the FAIR Plan [Fact sheet; reporting revisions and DIC separation]. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/CDI-Fact-Sheet-Summary-on-Residential-Insurance-Policies-and-the-FAIR-Plan.pdf
