# Coverage and Definition Sensitivity in California Home Insurance Measures

Sijan Poudel | J. Mack Robinson College of Business, Georgia State University, Atlanta, Georgia, USA

Revised after additional exploratory robustness checks. This version supersedes the earlier numerical interpretation only where expressly discussed below.

## Abstract

Public insurance measures depend on geographic coverage, event definitions and normalization. Using 8,503 California ZIP-year records for 2018–2021, this study compares state descriptive shares before and after restriction to published federal nonrenewal data. Federal values cover 73.13% of records but 99.843% of the pooled constructed normalizing total. Geographic restriction changes annual statewide insurer-initiated shares by approximately −0.0016 to −0.0051 percentage points. Under the primary minimum of 100 recorded counts and annual top-decile rule, 2.55%–5.10% of hotspots lack federal values; none are omitted with a 200-count minimum. Insurer-only and combined definitions retain 39.49–78.34% of insurer-defined hotspots in common. Additional checks vary selection rules, use new plus renewed policies as an alternative descriptive normalizer, leave out each county, and reconcile overlapping releases. Across the full definition grid, retention ranges from 27.40–78.48%. The alternative normalizer yields primary-rule retention of 39.49–77.07%. Results concern released counts and expressly defined indices, rather than household insurance-loss probabilities.

Keywords: homeowners insurance; nonrenewals; cancellations; geographic coverage; measurement; California

## 1. Introduction

Public insurance data help researchers describe insurance-market stress and identify locations receiving policy attention. The resulting conclusions depend on which places are observed, which events are counted, and which denominator is used. A dataset can omit many geographic labels while representing most recorded activity; an event definition can also change local rankings even when the underlying sample is fixed.

This study asks how published federal availability and alternative California event definitions change descriptive measures during 2018–2021. It holds the California outcome fixed when restricting geographic coverage. It separately compares insurer-initiated and combined insurer/policyholder termination categories. A third exercise checks how results respond to a different descriptive denominator.

The contribution is an empirical measurement audit with reproducible comparisons. The study does not claim that insurance-data limitations are newly discovered. Its results do not validate federal rate levels against an identical state target, establish a causal climate effect, or measure household uninsurance.

## 2. Related research

Liao et al. (2022) examine California initiation categories alongside wildfire risk and social vulnerability and distinguish postal ZIP codes from Census ZIP Code Tabulation Areas (ZCTAs). Gourevitch and Kousky (2025) describe patterns and limitations in the federal Property and Casualty Market Intelligence (PCMI) data. Heitfield (2026) flags geographic selection concerns in Florida while studying hurricane-model uncertainty and premiums. Koller (2025) applies federal ZIP-level data to California insurance-market conditions.

The present analysis extends these discussions through within-California comparisons of federal availability, recorded-count coverage, and hotspot membership under alternative definitions. Official source documentation is integral to this contribution: California termination fields include cancellations, federal nonrenewals exclude separately recorded cancellations, and subsequent California releases revise reporting methods and overlapping years.

## 3. Data and measurement

The primary input is the California Department of Insurance (CDI) ZIP workbook for 2015–2021, restricted to 2018–2021 (CDI, n.d.-a). It contains 8,503 ZIP-year observations and 2,323 distinct ZIP labels. New policies (N), renewed policies (R), insurer-initiated terminations (I), and policyholder-initiated terminations (U) are retained. The two termination categories include reported nonrenewals and cancellations (CDI, 2022a). CDI clarified the treatment of nonpayment as consumer-initiated starting in 2020; changes over time may therefore include reporting effects.

The primary constructed normalizer is T = R + I + U. The insurer-initiated descriptive share is 100 I/T; the combined share is 100 (I + U)/T. These are indices of recorded transactions. T is not a verified renewal cohort, year-end stock, count of unique policies, or count of households. Zero denominators remain undefined.

For the denominator sensitivity, D = N + R is used as an additional descriptive normalizer. CDI uses new-plus-renewed counts in published comparisons of termination activity. D also is not a verified at-risk renewal cohort, and I/D or (I+U)/D must not be interpreted as household probabilities. Annual event flows relative to such a denominator need not be bounded by 100%.

Federal availability is determined from the FIO 2018–2022 workbook matched on ZIP and year. A finite numeric nonrenewal entry, including zero, is usable in this sample. All matched entries pass the original review screen. Unavailable observations have no federal ZIP-year match; absence alone does not distinguish disclosure suppression, collection coverage, or geography. The federal HO-3/HO-5 population and year-end stock denominator differ from California's broader residential collection.

County context uses the fixed 2013 USDA Rural–Urban Continuum Codes: 1–3 for metropolitan counties and 4–9 for nonmetropolitan counties. Missing-county observations are retained in statewide totals and excluded from assigned county-context comparisons. Census sensitivity uses exact label membership in the fixed 2020 ZCTA Gazetteer. Such membership does not verify historical postal delivery type or insured-property location.

## 4. Methods

ZIP identifiers are preserved as five-character strings. The state panel is left-joined to federal values; missing measures are never replaced by zero. Original annual counts reconcile to 16 official state year-variable totals. The original complete R pipeline and its 44 regression checks are rerun before the extension. Supplementary Python independently imports the earlier California workbook and compares every study-year count with the R panel.

Coverage is measured both by the fraction of ZIP-year records and by their share of summed T. Annual aggregate shares are formed by summing numerators and denominators before division. The geographic restriction effect is the visible-subset share minus the all-record share in percentage points. If w is the visible fraction of T, this difference equals (1−w)(s_visible−s_missing). This is an accounting identity, not a model of why observations are missing.

The primary local rule requires T ≥ 100 and selects the annual highest 10% of I/T, including all cutoff ties. Definition comparisons use identical eligible samples and rank I/T and (I+U)/T separately. Retention is the shared count divided by the insurer-defined hotspot count; Jaccard overlap divides the shared count by the union. Rank agreement uses average-rank Spearman correlation.

New definition sensitivity combines T minima of 50, 100 and 200 with top fractions of 5%, 10% and 20%. For paired denominator comparisons the T≥100 eligibility rule is kept fixed and D>0 is required for both scores. This separates the effect of normalization from changing the minimum-count population. Both event definitions are compared under each denominator, and each event definition is also compared across denominators.

Each of the 58 known counties is excluded in turn, retaining unknown-county records in statewide totals. The eligible local sample and annual ranking cutoffs are recomputed after every exclusion. Aggregate selection, county-context gaps, definition retention and hotspot omission are recalculated. These are influence checks rather than uncertainty intervals.

The later 2020–2023 California ZIP workbook is compared with the earlier release in 2020–2021 using new, renewed and combined termination counts. Both all-record totals and matched-key totals are reported. The later combined category cannot identify insurer and policyholder components separately; no allocation is imposed and no revisions are spliced into the primary historical panel.

All new checks were added after inspection of the earlier report and are exploratory. No p-values are needed for these deterministic released-record comparisons. Reporting-period summaries are descriptive and do not estimate the causal effect of the 2020 clarification.

## 5. Primary results reproduced

Table 1. Federal availability

| Year | State records | Visible records | Visible records % | Visible T % |
| --- | --- | --- | --- | --- |
| 2,018 | 2,120 | 1,558 | 73.491 | 99.861 |
| 2,019 | 2,103 | 1,554 | 73.894 | 99.844 |
| 2,020 | 2,154 | 1,553 | 72.098 | 99.833 |
| 2,021 | 2,126 | 1,553 | 73.048 | 99.835 |

Table 2. Geographic restriction, primary normalizer

| Year | All % | Visible % | Difference, pp |
| --- | --- | --- | --- |
| 2,018 | 1.950 | 1.949 | -0.001606 |
| 2,019 | 2.743 | 2.738 | -0.005062 |
| 2,020 | 2.162 | 2.157 | -0.004516 |
| 2,021 | 2.765 | 2.763 | -0.001644 |

The visible subset covers 6,218 of 8,503 records. The missing 2,285 records represent approximately 0.157% of pooled T. Annual statewide differences remain very small, despite some higher descriptive shares among missing observations. Count weight explains the difference between geographic-record absence and aggregate impact.

Table 3. Primary hotspot omission

| Year | Hotspots | Omitted | Omitted % | Hotspot T omitted % |
| --- | --- | --- | --- | --- |
| 2,018 | 157 | 8 | 5.096 | 0.584 |
| 2,019 | 157 | 4 | 2.548 | 0.156 |
| 2,020 | 157 | 6 | 3.822 | 0.236 |
| 2,021 | 157 | 6 | 3.822 | 0.223 |

Table 4. Primary definition agreement

| Year | Insurer hotspots | Shared | Retention % | Jaccard % | Spearman |
| --- | --- | --- | --- | --- | --- |
| 2,018 | 157 | 62 | 39.490 | 24.603 | 0.584 |
| 2,019 | 157 | 123 | 78.344 | 64.398 | 0.789 |
| 2,020 | 157 | 116 | 73.885 | 58.586 | 0.734 |
| 2,021 | 157 | 103 | 65.605 | 48.815 | 0.722 |

The original pooled stable-cohort analysis retains 1,554 ZIPs meeting T≥100 in each of four years. Its 156 pooled hotspots include four with an incomplete federal history, representing 0.156989% of pooled hotspot T. This differs from annual omission because eligibility and the missing-history definition change. The original metro–nonmetro gap changes by at most 0.015993 percentage points on all positive-T records.

The original primary lists share 62, 123, 116 and 103 hotspots out of 157 in 2018–2021. The combined numerator changes local identification; its higher aggregate level is mechanically expected and is not itself a novel finding. Original Census-label-matched checks retain the conclusion of definition disagreement. These results describe ZIP labels, not verified populations of residential communities.

## 6. Additional robustness and release reconciliation

Across 36 annual combinations of minimum count and top fraction, insurer-hotspot retention is 27.40–78.48%. The supplement reports every specification rather than selecting only the largest disagreement. Changing the minimum alters the eligible population, so differences across rows are not attributed solely to estimator precision.

Table 5. Alternative-normalizer definition agreement, T ≥ 100, D > 0, top 10%

| Year | Eligible | Insurer hotspots | Shared | Retention % | Jaccard % |
| --- | --- | --- | --- | --- | --- |
| 2,018 | 1,562 | 157 | 62 | 39.490 | 24.603 |
| 2,019 | 1,563 | 157 | 121 | 77.070 | 62.694 |
| 2,020 | 1,566 | 157 | 118 | 75.159 | 60.204 |
| 2,021 | 1,567 | 157 | 107 | 68.153 | 51.691 |

Table 6. Hotspot retention when only the denominator changes

| Year | Numerator I or C | T-based hotspots | Shared with D | Retention % |
| --- | --- | --- | --- | --- |
| 2,018 | I | 157 | 152 | 96.815 |
| 2,018 | C | 157 | 151 | 96.178 |
| 2,019 | I | 157 | 151 | 96.178 |
| 2,019 | C | 157 | 149 | 94.904 |
| 2,020 | I | 157 | 153 | 97.452 |
| 2,020 | C | 157 | 143 | 91.083 |
| 2,021 | I | 157 | 154 | 98.089 |
| 2,021 | C | 157 | 145 | 92.357 |

With D = new plus renewed policies, insurer-versus-combined retention ranges from 39.49–77.07% under the paired primary local rule. The denominator-only comparison in Table 6 separates this issue from event-definition disagreement. Any sample losses from D=0 are tabulated in the supplement; they must not be counted as low scores.

Table 7. Statewide selection differences under both normalizers

| Year | Normalizer | All % | Visible % | Difference, pp |
| --- | --- | --- | --- | --- |
| 2,018 | T | 1.950 | 1.949 | -0.001606 |
| 2,018 | D | 1.935 | 1.934 | -0.001550 |
| 2,019 | T | 2.743 | 2.738 | -0.005062 |
| 2,019 | D | 2.717 | 2.712 | -0.004870 |
| 2,020 | T | 2.162 | 2.157 | -0.004516 |
| 2,020 | D | 2.145 | 2.141 | -0.004402 |
| 2,021 | T | 2.765 | 2.763 | -0.001644 |
| 2,021 | D | 2.769 | 2.767 | -0.001618 |

Across county exclusions, statewide visible-minus-all differences range from -0.005849–-0.001111 percentage points. Definition retention ranges from 37.58–80.00%, and insurer-hotspot omission ranges from 1.95–5.41%. These ranges pool counties and years; year-specific results and the county producing each extreme are provided in the supplement.

Table 8. Overlapping-release count comparisons

| Year | N, R or C | Earlier count | Later count | Later minus earlier | Change % |
| --- | --- | --- | --- | --- | --- |
| 2,020 | N | 1,057,402 | 1,007,422 | -49,980 | -4.727 |
| 2,020 | R | 7,631,979 | 7,572,809 | -59,170 | -0.775 |
| 2,020 | C | 992,227 | 898,064 | -94,163 | -9.490 |
| 2,021 | N | 1,107,169 | 1,091,089 | -16,080 | -1.452 |
| 2,021 | R | 7,621,326 | 7,514,564 | -106,762 | -1.401 |
| 2,021 | C | 1,118,422 | 1,037,767 | -80,655 | -7.211 |

N denotes new policies, R renewed policies, and C the combined termination count. The releases are compared on their published definitions; common-key results are separately provided. CDI's later documentation identifies improved reporting, removal of flat-cancellation inflation, and separation of Difference in Conditions (DIC) policies (CDI, n.d.-c). Cross-release differences therefore require substantive disclosure; they cannot simply be treated as random revisions or allocated between I and U.

Across all records, the later release's combined termination count is 9.49% lower in 2020 and 7.21% lower in 2021. Similar differences remain on matched ZIP-year keys, so unmatched locations alone do not explain the revisions. These differences qualify the data-vintage scope of the benchmark.

The historical insurer/policyholder decomposition remains tied to the older release because the later file does not supply the same split. Reconciliation does not establish that the old classifications are the best available measures of current conditions. The paper is a benchmark of specified historical releases.

## 7. Discussion and limitations

The reproduced primary results support aggregate robustness to the observed geographic restriction. They do not support a general claim that federal absence creates large statewide distortion. Local omission depends on the eligible count population. Definition and denominator checks show exactly which geographic conclusions depend on measurement choices; readers should use the complete tables when judging their stability.

State and federal records cover different policy populations and count different events. This design cannot validate federal rate levels, identify every source of selection, infer household replacement coverage, or measure individual FAIR Plan transitions. The primary and alternative normalizers are descriptive constructions, and source transactions may not correspond to mutually exclusive unique policies.

Later-release reconciliation and the 2020 reporting clarification limit temporal interpretation. New release differences must remain separate from insurer-specific outcomes that cannot be reconstructed. Even an independently reproduced extraction does not validate the underlying insurer submissions.

Postal ZIP labels and Census ZCTAs are not interchangeable. The earlier source check for ZIP 93016 reproduces I=95, R=53 and U=7 in 2020 (T=155; I/T=61.29%), but does not independently verify reporting origin or insured-property geography. Threshold checks and label-matched sensitivity address some consequences without certifying that record as household-level risk evidence.

The study is exploratory, covers one state and four historical years, and contains no causal identification or probability-based sampling inference. No statistical significance claim is attached to the calculated differences. Robustness is evaluated against declared alternatives, not by adding models to obtain a preferred result.

## 8. Conclusion

The California benchmark quantifies how published federal availability changes explicitly defined state summaries and hotspot representation. Aggregate geographic restriction effects are small in the original release. Local omission is concentrated among smaller records, while definition choice changes hotspot membership. The added denominator, county-influence and cross-release checks qualify the scope of those conclusions. Public insurance-data applications should disclose their vintage, numerator, normalizer, eligibility rule and geographic coverage together.

## Data, code and verification

Code: https://github.com/sijanpoudel-hub/california-home-insurance-measurement . The extension and report generator are preserved on the analysis branch. This revision was generated only after the complete original R pipeline and supplementary checks succeeded. The 44 original regression checks verify reproduction of saved quantities; supplementary checks compare every original study-year count with an independent Python workbook import and reproduce the main selection and hotspot results. This is not independent validation of insurer submissions.

Run record: https://github.com/sijanpoudel-hub/california-home-insurance-measurement/actions/runs/45936786009

Input fingerprints, acquisition records, full numerical outputs, software versions and source references accompany the report. The 2020–2023 workbook has its own SHA-256 manifest. New robustness exercises are labelled exploratory. The reproducible numerical outputs are authoritative if a rounding difference appears in the displayed text.

## Declarations

Funding: No external funding. Competing interests: None declared. Data and ethics: Publicly released aggregate records; no individual policyholder information. Generative AI assistance: ChatGPT assisted with research design, literature searches, source checks, code, execution, interpretation and manuscript preparation. The author remains responsible for reviewing the results, citations and submission.

## References

California Department of Insurance. (2022a). Insurance Policy Count Data 2015–2021 [Fact sheet, December 2022]. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/CDI-Fact-Sheet-Residential-Insurance-Market-Policy-Count-Data-December-2022.pdf

California Department of Insurance. (2022b). Number of New, Renewed, and Non-Renewed Homeowners’ Policies: County Analysis 2015–2021. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Insurance-Policy-Analysis-by-County-2015-to-2021-2.pdf

California Department of Insurance. (n.d.-a). Residential Property Voluntary Market New, Renewed and Nonrenewed Policies by ZIP, 2015–2021 [Excel workbook]. Official data portal: https://www.insurance.ca.gov/01-consumers/200-wrr/DataAnalysisOnWildfiresAndInsurance.cfm

California Department of Insurance. (n.d.-b). Residential Insurance Voluntary Market New, Renewed and Nonrenewed Policies by ZIP, 2020–2023 [Excel workbook]. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Insurance-Voluntary-Market-New-Renew-NonRenew-by-ZIP-2020-2023.xlsx

California Department of Insurance. (n.d.-c). Summary on Residential Insurance Policies and the FAIR Plan [Fact sheet; reporting revisions and DIC separation]. https://www.insurance.ca.gov/01-consumers/200-wrr/upload/CDI-Fact-Sheet-Summary-on-Residential-Insurance-Policies-and-the-FAIR-Plan.pdf

California Volunteers. (n.d.). Look up your county by ZIP code. https://www.californiavolunteers.ca.gov/look-up-your-county-by-zip-code/

Federal Insurance Office, U.S. Department of the Treasury. (2025a). Analyses of U.S. Homeowners Insurance Markets, 2018–2022: Climate-Related Risks and Other Factors. https://home.treasury.gov/system/files/311/Analyses_of_US_Homeowners_Insurance_Markets_2018-2022_Climate-Related_Risks_and_Other_Factors_0.pdf

Federal Insurance Office, U.S. Department of the Treasury. (2025b). Supporting Underlying Metrics and Disclaimer [Excel workbook]. https://home.treasury.gov/system/files/311/Supporting_Underlying_Metrics_and_Disclaimer_for_Analyses_of_US_Homeowners_Insurance_Markets_2018-2022.xlsx

Gourevitch, J. D., & Kousky, C. (2025). New homeowners insurance data reveals insights into market trends and suggests future research needs. Risk Management and Insurance Review, 28(2), 324–338. https://doi.org/10.1111/rmir.70010

Heitfield, E. (2026). Model Uncertainty and the Pricing of Hurricane Risk in Florida. FEDS 2026-016. https://doi.org/10.17016/FEDS.2026.016

Koller, S. (2025, May 27). California’s homeowners insurance market is a national bellwether. Harvard Joint Center for Housing Studies. https://www.jchs.harvard.edu/blog/californias-homeowners-insurance-market-national-bellwether

Liao, Y., Walls, M. A., Wibbenmeyer, M., & Pesek, S. (2022, November 30). Insurance availability and affordability under increasing wildfire risk in California. Resources for the Future. https://www.rff.org/publications/issue-briefs/insurance-availability-and-affordability-under-increasing-wildfire-risk-in-california/

U.S. Census Bureau. (2023). ZIP Code Tabulation Areas. https://www.census.gov/programs-surveys/geography/guidance/geo-areas/zctas.html

U.S. Census Bureau. (n.d.). 2020 Gazetteer Files [National ZCTA reference]. https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/2020_Gaz_zcta_national.zip

U.S. Department of Agriculture, Economic Research Service. (n.d.). 2013 Rural–Urban Continuum Codes. https://ers.usda.gov/data-products/rural-urban-continuum-codes
