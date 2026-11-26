# Measure definitions

## California counts

For each ZIP-year:

| Symbol | Saved field | Meaning |
|---|---|---|
| R | `renewed` | Recorded renewed-policy count |
| I | `insurer_nonrenewed` | Insurer-initiated count under the source label |
| U | `insured_nonrenewed` | Policyholder-initiated count under the source label |
| T | `recorded_count_total` | Constructed total R + I + U |

The California source columns labelled nonrenewals include cancellations. Preserve the original fields, but describe their scope when interpreting them.

The descriptive insurer-initiated share is I/T. The combined termination share is (I+U)/T. Display percentages as 100 times the corresponding share. A zero T produces an undefined share, stored as missing rather than zero.

T is a constructed normalizer. It is not established to be a unique-policy population, a household count, or policies at risk of renewal. Counts may represent multiple transactions relating to a policy.

## Statewide and pooled measures

Sum the relevant numerators and denominators, then divide. Do not substitute an unweighted average of ZIP-level percentages.

The pooled ZIP analysis sums four years of counts before division. Its principal sample requires all four observed years and T of at least 100 in every year. A four-year sum of at least 400 alone does not satisfy this rule.

## Federal availability

Match exact five-character ZIP and year keys. Preserve every eligible California record.

- An explicitly published numeric zero is visible.
- An absent ZIP-year or blank value is unavailable; do not replace it with zero.
- An unusable published value has its own quality flag.

The supplied pilot had no unusable published California matches. Absence alone does not reveal why a record is unavailable.

The federal nonrenewal rate divides nonrenewal counts by policies in force at year end. It is a different measure from the California constructed share. Preserve it separately.

## Hotspot comparisons

On each annual eligible sample, select the highest 10% of California insurer-initiated shares. Use ceiling(0.10 times eligible records) to locate the cutoff and retain all cutoff ties.

Hotspot omission is the number of selected hotspots without a usable federal value divided by all selected hotspots. Count-weighted omission divides T belonging to those omitted hotspots by T across all selected hotspots.

For definition agreement, independently select hotspots using insurer-only and combined shares on identical annual samples. Retention is their shared count divided by insurer-defined hotspots. Jaccard overlap is the shared count divided by the union.

## Geographic context

USDA's fixed 2013 county classification defines metro and nonmetro context. It does not classify individual residents or every location within a county.

The 2020 ZCTA sensitivity matches labels, excludes nonmatches from the sensitivity sample, and reranks that sample. It does not remap insured properties or correct the primary sample. Missing county labels remain in statewide calculations but cannot be assigned metro or nonmetro context without an identified reference.
