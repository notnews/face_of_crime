# NCVS source and measurement

The analysis uses the Bureau of Justice Statistics (BJS) **NCVS Select – Personal Victimization** public API. The preserved response has one row per sampled personal victimization, 49,717 rows from survey years 1993–2014. BJS describes the fields in its [person-level codebook](https://bjs.ojp.gov/document/NCVS_Select_person_level_codebook.pdf) and the [API access instructions](https://bjs.ojp.gov/national-crime-victimization-survey-ncvs-api). The response was downloaded on 2026-10-24 UTC from:

```text
https://api.ojp.gov/bjsdataset/v1/gcuy-rt5g.csv?%24where=year%3E%3D%271993%27%20AND%20year%3C%3D%272014%27&%24limit=200000
```

The file is [`personal_victimizations_1993_2014.csv`](../data/reference/ncvs/personal_victimizations_1993_2014.csv), 10,721,923 bytes, SHA-256 `eb557d03ca690bb149e63f77a33bc1244359044ebb9dfecf0eb331355cf162d1`. It is committed so `make check` needs no network. A future API response may change; replacing this file is a new source-data change and requires a comparison with the pinned version.

## Analysis fields

| API field | Meaning used here |
|---|---|
| `year` | Survey collection year; 1993–2014 in this snapshot. |
| `newoff` | Crime type: 1 rape/sexual assault, 2 robbery, 3 aggravated assault, 4 simple assault, 5 personal theft/larceny. |
| `seriousviolent` | 1 rape/sexual assault, robbery, or aggravated assault; excludes simple assault and homicide. |
| `sex` | Victim sex: 1 male, 2 female. |
| `race_ethnicity` | Victim race and Hispanic origin: 1 non-Hispanic White, 2 non-Hispanic Black, 3–5 other non-Hispanic groups, 6 Hispanic. |
| `offendersex` | Victim-reported offender sex: 1 male, 2 female, 3 both male and female, 4 unknown, 98 residue. This describes incidents, not a count of individual offenders. |
| `newwgt` | Series-adjusted annual victimization weight. Its weighted annual shares reproduce the preserved NCVS spreadsheet. |
| `wgtviccy` | Unadjusted annual victimization weight; using it instead changes the estimated shares. |

For a given crime and set of survey years, a pooled victim share is the sum of `newwgt` for victimizations in the group divided by the sum of `newwgt` for all victimizations in that crime and year set. This is a share of estimated victimizations, not a victimization rate within a demographic population. A person may contribute more than one victimization. NCVS covers nonfatal crimes reported and not reported to police among people age 12 or older living in sampled U.S. households.

For the female-offender comparison, the numerator is the weighted count of serious-violent incidents reported to have female-only offenders. The denominator includes incidents reported to have male-only, female-only, or mixed-sex offenders; unknown and residue codes are excluded. These are incidents as reported by victims, not distinct offenders or arrests. The API response includes pseudo-stratum and half-sample codes, but BJS's [direct variance guide](https://bjs.ojp.gov/sites/g/files/xyckuh236/files/media/document/ncvs_variance_user_guide_11.06.14.pdf) also requires a modified incident file with dummy records for every PSU and year-group handling for pooled estimates. Those steps have not been reconstructed from this API subset, so the plots show survey point estimates without standard errors.

The original [`ncvs.csv`](../data/reference/ncvs/ncvs.csv), [`ncvs_hispanic.csv`](../data/reference/ncvs/ncvs_hispanic.csv), and [`Victimization.xlsx`](../data/reference/ncvs/Victimization.xlsx) remain as historical handoffs. The API's series-adjusted weight reproduces every numeric annual cell in both CSVs within 0.05 percentage points, the precision of their one-decimal spreadsheet cells. The tests enforce this check. Two cells suppressed as `--` in the archived CSV can be calculated from the pinned records.
