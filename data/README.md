# Data

## Stages

- `raw/`: preserved input bytes. `episodes/` contains the coding sheets; `census/` and `ucr/` contain the original collected workbooks; `ncvs/` contains the BJS API response; `nypd/` contains enforcement workbooks, homicide PDFs, and the arrest API response. Annual NYPD reports use `year=YYYY/` partitions.
- `reference/`: original annual CSV and spreadsheet handoffs used to check extraction. They do not drive the estimates. `literature.csv` supplies the literature table.
- `extracted/`: automatically rebuilt CSVs with named analytical fields; ignored by Git.
- `build/`: automatically rebuilt R objects for estimation and exhibits; ignored by Git.

The six active episode sheets contain 194 Criminal Intent, 151 original-series, and 386 SVU rows. `svu_template.csv` is an incomplete 385-row template, preserved but unused. Each row is a coded episode or combined episode entry, not a person.

See [source schemas and extraction details](sources.md).

## Reproduce

Run `make restore` followed by `make check` from the repository root. Preparation verifies every preserved input against [source_manifest.csv](source_manifest.csv), reads the original files, and rebuilds the extracts. `make download` retrieves missing inputs from their manifest URLs and accepts them only if their SHA-256 matches. It never silently refreshes a changed response. Retrieval dates are blank where the original download date is unknown. Older repository inputs have URLs pinned to their original Git commit. [The path map](../docs/path_map.csv) records relocations without keeping duplicate copies.

The paper's reference-data appendix gives the source definitions, pooled estimates, covered years, denominators, rounding ranges, and uncertainty limitations. [reference_inventory.csv](../tabs/reference_inventory.csv) is its generated numerical companion. Original Census and UCR workbooks are collected inputs from the original project; extraction from these workbooks is automatic, but their upstream compilation is not reconstructed.

Main comparisons pool counts or survey weights over the intersection of available source years and years with coded episodes in any series. NCVS contributes 1999–2014; UCR race/sex 1999–2015; UCR Hispanic ethnicity 2013–2015; NYPD enforcement and rape arrests 2008–2015. Female homicide victims use 2010–2012, known suspects 2011–2012, and arrested suspects 2010 separately. Annual tables report year-specific percentages.

## Coding rules

- Race: `white`, `black`, `hispanic`, and `asian` are counted as mutually exclusive categories, following the source sheets. `unknown`, `mixed`, and other unclassified labels are excluded from known-race denominators.
- Gender: `male` and `female` are counted as written. An asterisked `Female*` entry is retained as unclassified pending a coding decision; its source note says `*Transgender`.
- Comma-separated labels may include an explicit count (`2 black`) or a single unnumbered label (`Black`). Extra whitespace, plurals, and a missing space in `1hispanic` are parsed. The source values remain unchanged.
- The “Mushrooms” row in the original series has race and gender labels in each other’s columns for both roles. The reader corrects that one transposition without changing the source file.
- An episode can appear in both the murder and rape subsets if its crime field contains both words. Annual estimates pool classified characters in the coded episodes broadcast that year.

The [coding discrepancy table](../tabs/coding_discrepancies.csv) lists rows whose classified race or gender count exceeds the stated number of victims or criminals. The audit also records duplicate episode identifiers and missing declared totals. These cases remain in the published source files; the pipeline does not infer replacements for ambiguous counts or identifiers.
