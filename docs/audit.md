# Audit of *The Face of Crime in Prime Time*

## Main findings

The corrected analysis still shows Black characters at lower shares than several historical arrest and victimization benchmarks. Several coding defects changed numerical results, and the original build was not reproducible as written. The comparisons remain descriptive: the show and reference files cover different crimes, populations, geographies, and periods. The data do not test whether watching the shows changes beliefs.

| Confirmed issue | Original | Corrected | Where it matters |
|---|---:|---:|---|
| New York women in the Census comparison | 76.3%, 72.2%, 71.4% in 1990, 2000, 2010 | 53.2%, 52.6%, 52.5% | Annual victim and criminal gender tables. The old code renamed the seventh of nine Census columns `men_ny`; that column is Hispanic share. |
| Black criminal share, all coded episodes | 7.49% CI; 9.64% SVU; 10.58% Original | 7.73% CI; 9.86% SVU; 11.17% Original | Aggregate Black-criminal figures and paper. Criminal-race denominators used the victim Asian count; one Original episode also had transposed race and gender labels. |
| Black victim share, Original, 2005 | 8.33% | 4.35% | Annual victim-race figure and table. The old annual denominator used criminal Hispanic counts. This is the largest annual change. |
| Black criminal share, SVU, 2014 | 16.13% | 17.86% | Annual criminal-race figure and table. The annual denominator used victim Asian counts. |
| SVU known criminal-race denominator | 434 | 436 | The new parser recognizes `1hispanic` and an Asian count after two spaces. The old parser returned zero and `NA`, respectively. |

The transposed “Mushrooms” labels also change the Original Black-victim share from 9.95% to 10.42%. The paper now reports 659 episodes with murder, rape, or assault. Two source rows describing false rape accusations had previously been counted as rape episodes. The original aggregate and annual R scripts remain available in [the pre-modernization commit](https://github.com/notnews/face_of_crime/tree/7df611f/scripts). To verify old values, check out that commit in a disposable worktree and set `basedir` to its parent. The original aggregate script stops at `colMeans(ncvs_hisp)` because the historical NCVS CSV contains `--` markers; the baseline calculation treated these as missing in the disposable copy. The new reader declares `--` as missing without editing the source. The original PDF build also required an unavailable `apsr.bst`; the manuscript now uses the installed `plainnat` bibliography style.

The episode data give race and gender totals for each episode, but do not link a coded character to an individual offense. Earlier figures plotted all victims or criminals in episodes tagged rape or murder beside offense-specific reference shares. For example, the 69.1% female point for victims in SVU rape-tagged episodes included victims of other offenses; 98 of the 195 rape-tagged episodes were also tagged murder. It could not be read as the female share of rape victims. The six main figures now show only all-episode character shares and label the offense-specific references as context. The corresponding rape- and murder-specific claims were removed from the manuscript. Aggregate output no longer generates the episode-subset shares.

## What each comparison measures

| Claim family | Unit and denominator | Reference quantity | Interpretation |
|---|---|---|---|
| Show race and gender shares | Coded character counts pooled across episodes; classified characters for that attribute are the denominator | None | Composition of the coded show characters, not unique actors, viewers, or crimes. |
| Arrest comparisons | Same show shares | Historical UCR arrest shares or NYPD suspect shares | Difference in recorded composition across unlike offense mixtures and enforcement systems; it does not identify crime commission rates. |
| Victim comparisons | Same show shares | Historical NCVS victimization or UCR/NYPD murder-victim shares | Difference in recorded composition; NCVS excludes homicide and its survey categories differ from the show coding. |
| Population comparisons | Same show shares | Three Census snapshot years | Population composition is context, not a matched crime baseline. |

The main plots show one pooled dot per historical measure, using the intersection of its available years and years with a coded episode from any series. NCVS contributes 1999–2014, UCR contributes 1999–2015, and NYPD contributes 2008–2015. The old 18.5% NCVS Black serious-violence figure was an unweighted mean of annual percentages for 1993–2014; the pooled estimate is 19.1%. This is a share of victimizations involving non-Hispanic Black victims, not a rate of victimization among Black people. The early Original episodes have no NCVS or UCR years. The annual tables retain the single-year comparisons. The archived NYPD workbooks have known-race counts that permit pooled estimates from their rounded annual percentages; the single ambiguous integer count changes one pool by 0.012 percentage points. See [NYPD reference construction](../data/sources.md). The NCVS API file covers the same historical years as the old handoff, with its retrieval URL and hash pinned separately.

## Remaining source and design limits

- The “Mushrooms” source row has race and gender entered in each other’s columns for both roles. The new reader swaps those labels for that row and leaves the source file intact; one person per role is classified from the labels.
- Twelve episode-role-attribute combinations have classified counts above the declared number of characters; the affected rows are in [`coding_discrepancies.csv`](../tabs/coding_discrepancies.csv). Twenty-nine victim totals and 21 criminal totals are missing or nonnumeric. The source sheets cannot resolve all of these conflicts, so the pipeline keeps their classified category counts and reports the discrepancy.
- SVU has one repeated season/episode identifier: season 4, episode 4 labels both “Deception” and “Lust.” Both source rows remain; the episode identifier needs verification against an independent episode list before changing either row.
- The asterisked `Female*` entry has a `*Transgender` note. Its intended coding category is ambiguous. The analysis preserves the original exclusion rather than inferring an identity from that note. The additional 385-row SVU template is largely empty and is not an analysis input.
- The NCVS annual shares are rebuilt from the pinned official API records and match every numeric cell in the archived CSVs to its displayed precision. UCR arrest and murder-victim annual shares are rebuilt from the archived count workbooks. NYPD pooled shares are reconstructed from the archived workbooks' known-race counts and rounded percentages; the Census tables are extracted from the archived workbook, while the original upstream compilation of the Census and UCR workbooks remains undocumented. The audience calculation in the original `05_audience.R` depends on absent files; its three historical audience averages remain in the manuscript with their original attribution and cannot be rebuilt from this repository.
- NCVS rape/sexual assault is a survey estimate of victimizations. The pooled female share is 88.7%, not an estimate for the show's rape victims. The API supplies design codes, but valid pooled standard errors require the BJS modified incident file and year-group procedure; these have not been reconstructed here. NCVS dots therefore show point estimates only.
- This is a census of the available coded episodes, not a random sample of television programming. The paper does not attach sampling intervals to its show shares. Any generalization beyond these episodes, or causal claim about viewer beliefs, requires additional design and data.

## Checks performed and gates

| Check | Result |
|---|---|
| Source hashes and row counts | All 29 pinned source files match the manifest; 731 analysis rows partition into 194 CI, 151 Original, and 386 SVU. |
| Parser, category sums, and denominators | Tests cover count syntax, ambiguous labels, and reconciliation of every share with its category counts. |
| Source missingness and duplicate keys | `--` parsed as missing; missing declared totals and one duplicate key recorded. |
| External benchmark mapping | Nine Census columns mapped by name; all NCVS annual cells reconciled with the archived handoff; UCR arrest shares reconciled to the count workbook. |
| Inference and identification | No inferential estimator is used for the episode census; benchmark comparability and causal interpretation are limited as above. |
| Figures, tables, and prose | Generated from one R pipeline; headline manuscript values are macros from the analysis. |
| External source extraction | Pinned BJS API response, UCR workbooks, and NYPD workbooks drive the corresponding estimates. Census tables are extracted from the archived workbook. The upstream compilation of the original Census and UCR workbooks is not reconstructed. |

## Possible future data update

A future refresh to newer survey or crime years should be a separate, reviewed commit. It should identify the exact official series and table for each comparison, state why the newer release improves measurement, save source URLs, retrieval dates, file hashes, and extraction code, then report old-vintage and new-vintage results side by side. This change pinned official NCVS records for the existing 1993–2014 period; it did not add newer survey years.
