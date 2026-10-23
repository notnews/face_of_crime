# The Face of Crime in Prime Time

Gaurav Sood and Daniel Trielli

[Paper](ms/face_of_crime.pdf) · [Audit and corrected results](docs/audit.md) · [Data](data/README.md)

## Question and findings

How do the race and gender of victims and criminals portrayed in three *Law & Order* series compare with historical crime and population records? The coded dataset contains 731 episodes: 151 from the original series, 194 from *Criminal Intent*, and 386 from *Special Victims Unit*.

Among characters whose race was classified, Black criminal and victim shares are lower than several historical arrest and victimization benchmarks. Those sources differ in crimes, geography, years, and how people enter the records. The generated [paper](ms/face_of_crime.pdf) reports the shares for each series. These are descriptive comparisons of coded episodes, not estimates of what viewers believe.

![Black criminal shares by show and historical comparison](figs/all_criminals_by_race.png)

The [paper](ms/face_of_crime.pdf) gives the other race and gender comparisons. The [audit](docs/audit.md) records the original and corrected values, remaining source discrepancies, and interpretation limits.

## Reproduce

Use R 4.6, `make`, and a LaTeX installation with `latexmk` and the packages used by the manuscript.

```sh
make restore
make check
```

`make check` regenerates the data products, figures, tables, and PDF, then runs `lintr` and `testthat`. `make ci-docker` runs the same checks in a standard Rocker image when Docker is available. The source files remain at their historical vintages. Their SHA-256 hashes are pinned in [`docs/source_manifest.csv`](docs/source_manifest.csv).

## Layout

| Path | Contents |
|---|---|
| `data/raw/` | Original coded episode CSV files. |
| `data/reference/` | Historical comparison CSVs and source spreadsheets. |
| `data/build/` | Rebuildable intermediate R objects; ignored by Git. |
| `R/` | Reading, coding, analysis, figure, and table functions. |
| `scripts/` | Configuration and ordered pipeline stages. |
| `figs/`, `tabs/` | Generated exhibits, numerical results, and manuscript macros. |
| `ms/` | Editable LaTeX manuscript, bibliography, and compiled PDF. |
| `tests/testthat/` | Source, coding, denominator, and benchmark tests. |
| `legacy/scripts/` | Original scripts retained for old-versus-new calculations. |

The pipeline runs `scripts/01_prepare_data.R` through `scripts/04_tables.R` with `scripts/99_run_all.R`. Each stage reads a file left by its predecessor. The manuscript inputs generated tables and macros, so corrected values reach both the exhibits and prose. [`docs/path_map.csv`](docs/path_map.csv) records published old and new data paths.

## Data and license

The coded episode data and historical comparison files come from the original repository. The data documentation describes the source files and their limits. This repository retains the original [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/) notice.
