# NYPD reference construction

The 2008–2015 NYPD homicide and rape comparisons use the eight archived `Enforcement Report Year ... tables.xls` workbooks in [`data/reference/ny_enforcement`](../data/reference/ny_enforcement). Each workbook's `page 1` holds murder and non-negligent manslaughter; `page 2` holds rape. The official [2015 NYPD report](https://www.nyc.gov/html/nypd/downloads/pdf/analysis_and_planning/year_end_2015_enforcement_report.pdf) displays the same race/ethnicity rows and the count of victims or suspects whose race/ethnicity is known.

The pipeline reads the reported Black and Hispanic percentages and the corresponding `Known Race Ethnicity` count for victims and suspects. Black and Hispanic are separate categories in these NYPD tables. Because the workbooks display percentages to one decimal place, the code derives the range of integer counts compatible with each annual percentage and uses the midpoint of the pooled range. Of 64 homicide and rape victim/suspect year/category cells, 63 imply one integer count. The 2012 rape-victim cell allows 438 or 439 Black victims out of 1,157 with known race/ethnicity; this changes the pooled rape-victim share by 0.012 percentage points. All Hispanic cells imply unique counts.

| NYPD measure | Years | Pooled Black share | Pooled Hispanic share |
|---|---:|---:|---:|
| Homicide victims | 2008–2015 | 62.2% | 26.4% |
| Rape victims | 2008–2015 | 39.5% | 37.3% |
| Homicide suspects | 2008–2015 | 58.7% | 32.4% |
| Rape suspects | 2008–2015 | 51.3% | 34.9% |

These are shares among NYPD records with known race/ethnicity. Suspects are not arrestees or distinct offenders, and the offense-specific NYPD shares do not describe the crime mix of all coded characters. The workbooks remain pinned in [`source_manifest.csv`](source_manifest.csv); this change uses no newer NYPD data.

These archived enforcement tables report race/ethnicity but do not report victim or suspect sex. The separate [NYPD rape arrest reference](ny_arrests_source.md) provides one checked female comparison from incident-level arrests.
