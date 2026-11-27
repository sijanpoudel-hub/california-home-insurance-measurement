# Additional exploratory analysis

These checks were added after inspecting the November 26, 2026 manuscript. They are not preregistered.

1. Reproduce the original R pipeline and its 44 regression checks before extending it.
2. Independently import every earlier California study-year count in Python and compare it with the R panel.
3. Compare insurer-only and combined hotspot definitions for all combinations of minimum T = 50, 100, 200 and top fractions = 5%, 10%, 20%, preserving cutoff ties.
4. Compare T = R + I + U with D = new + renewed policies. D is a descriptive agency-used count denominator, not a verified exposure or renewal cohort. Keep T >= 100 eligibility fixed and require D > 0 for paired ranking comparisons; tabulate excluded rows.
5. Leave each of the 58 counties out in turn, retaining unknown counties in statewide sums, reranking the remaining sample and recomputing aggregate selection, context gaps and definition agreement.
6. Compare earlier and later California releases in 2020–2021 using new, renewed and combined counts. Report unmatched keys and common-key versus all-record sums. Do not infer an insurer/policyholder split from later combined counts or splice releases.
7. Generate a revised main report and complete supplement from executed outputs. Preserve the original main specification and report all added checks as exploratory.

Official later-workbook URL:
https://www.insurance.ca.gov/01-consumers/200-wrr/upload/Residential-Insurance-Voluntary-Market-New-Renew-NonRenew-by-ZIP-2020-2023.xlsx

CDI reporting-revision documentation:
https://www.insurance.ca.gov/01-consumers/200-wrr/upload/CDI-Fact-Sheet-Summary-on-Residential-Insurance-Policies-and-the-FAIR-Plan.pdf

Source reporting accuracy, historical property geography and household replacement coverage remain outside the available data.
