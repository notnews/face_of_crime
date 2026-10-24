# NCVS source and measurement

The analysis uses the Bureau of Justice Statistics (BJS) **NCVS Select – Personal Victimization** public API. The preserved response has one row per sampled personal victimization, 49,717 rows from survey years 1993–2014. BJS describes the fields in its [person-level codebook](https://bjs.ojp.gov/document/NCVS_Select_person_level_codebook.pdf) and the [API access instructions](https://bjs.ojp.gov/national-crime-victimization-survey-ncvs-api). The response was downloaded on 2026-10-24 UTC from:

```text
https://api.ojp.gov/bjsdataset/v1/gcuy-rt5g.csv?%24where=year%3E%3D%271993%27%20AND%20year%3C%3D%272014%27&%24limit=200000
```

The file is [`personal_victimizations.csv`](raw/ncvs/personal_victimizations.csv), 10,721,923 bytes, SHA-256 `eb557d03ca690bb149e63f77a33bc1244359044ebb9dfecf0eb331355cf162d1`. It is committed so `make check` needs no network. A future API response may change; replacing this file is a new source-data change and requires a comparison with the pinned version.

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

The original [`annual_shares.csv`](reference/ncvs/annual_shares.csv), [`annual_race_ethnicity_shares.csv`](reference/ncvs/annual_race_ethnicity_shares.csv), and [`victimization.xlsx`](reference/ncvs/victimization.xlsx) remain as historical handoffs. The API's series-adjusted weight reproduces every numeric annual cell in both CSVs within 0.05 percentage points, the precision of their one-decimal spreadsheet cells. The tests enforce this check. Two cells suppressed as `--` in the archived CSV can be calculated from the pinned records.

# NYPD sources

The eight enforcement workbooks in `raw/nypd/enforcement/` cover 2008–2015. The parser reads homicide (page 1), rape (page 2), robbery (page 4), and felonious assault (page 5; named `page5` in 2010). It extracts White, Black, and Hispanic percentages plus known-race and total counts for victims and suspects. All 192 annual percentages are checked against the original handoff CSV. Black and Hispanic are separate categories.

One-decimal percentages imply ranges of integer counts. Pooled estimates use the midpoint of the compatible count range divided by pooled known-race totals. Among the 64 Black/Hispanic homicide/rape cells, only 2012 Black rape victims has more than one compatible count (438–439 of 1,157). Robbery and assault bounds are also retained in the generated reference inventory.

The official [2015 enforcement PDF](https://www.nyc.gov/html/nypd/downloads/pdf/analysis_and_planning/year_end_2015_enforcement_report.pdf) is preserved beside its workbook. The [NYPD archive](https://www.nyc.gov/site/nypd/stats/reports-analysis/archive.page) also supplies the 2010–2012 homicide reports, preserved under `raw/nypd/homicide/`. `pdftools::pdf_text()` extracts sex shares and denominators from pages 5 and 9. The parser checks the page count, unique matches, roles, and feasible integer ranges. The 2010 suspect page describes arrestees; 2011–2012 describe known suspects, arrested or not. They are never pooled together.

`raw/nypd/arrests/rape_arrests.json` preserves the unmodified NYC Open Data response for 2008–2015 rape arrests, grouped by year and `perp_sex`. The exact query is recorded in `source_manifest.csv`. It contains 151 female and 6,492 male arrests. Every annual total is within five of the archived enforcement report. The older CSV remains a validation handoff. A homicide query did not reconcile: 858 API arrests versus 308 in the 2015 report. The paper uses the separate homicide PDFs for sex comparisons; the cause of the API discrepancy remains unresolved.

# Census and UCR workbooks

`raw/census/population.xlsx` supplies the six US/New York White, Black, and male population-share columns for 1990, 2000, and 2010. `raw/ucr/arrests.xlsx` supplies annual arrest counts; `raw/ucr/homicide_victims.xlsx` supplies victim counts. These are original project workbooks. Their upstream manual compilation is not reconstructed. The R readers derive the analytical tables directly from these workbooks and compare them with preserved annual CSV handoffs where available. Female shares use the corresponding sex count denominator; UCR race and ethnicity have separate denominators. Murder-victim shares include unknown race or sex in the total.
