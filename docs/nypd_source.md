# NYPD reference construction

The 2008–2015 NYPD homicide and rape comparisons use the eight archived `Enforcement Report Year ... tables.xls` workbooks in [`data/reference/ny_enforcement`](../data/reference/ny_enforcement). Each workbook's `page 1` holds murder and non-negligent manslaughter; `page 2` holds rape. The official [2015 NYPD report](https://www.nyc.gov/html/nypd/downloads/pdf/analysis_and_planning/year_end_2015_enforcement_report.pdf) displays the same race/ethnicity rows and the count of victims or suspects whose race/ethnicity is known.

The pipeline reads the reported Black percentage and the corresponding `Known Race Ethnicity` count for victims and suspects. Black and Hispanic are separate categories in these NYPD tables. The pooled share weights each year's reported percentage by its known-race count. Because the workbooks display percentages to one decimal place, the code also derives the range of integer Black counts compatible with each annual percentage and uses the midpoint of the pooled range. Among the 32 homicide and rape victim/suspect year cells, 31 imply one integer count. The 2012 rape-victim cell allows 438 or 439 Black victims out of 1,157 with known race/ethnicity; this changes the pooled rape-victim share by 0.012 percentage points.

| NYPD measure | Years | Pooled Black share |
|---|---:|---:|
| Homicide victims | 2008–2015 | 62.2% |
| Rape victims | 2008–2015 | 39.5% |
| Homicide suspects | 2008–2015 | 58.7% |
| Rape suspects | 2008–2015 | 51.3% |

These are shares among NYPD records with known race/ethnicity. Suspects are not arrestees or distinct offenders, and the offense-specific NYPD shares do not describe the crime mix of all coded characters. The workbooks remain pinned in [`source_manifest.csv`](source_manifest.csv); this change uses no newer NYPD data.
