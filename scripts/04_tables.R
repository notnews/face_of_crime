source("scripts/00_config.R")
prepared <- readRDS(project_file("data", "build", "prepared_data.rds"))
results <- readRDS(project_file("data", "build", "results.rds"))
write_tables(
  results$shares$aggregate, results$shares$yearly, results$benchmarks,
  prepared$benchmarks, prepared$episodes, table_dir
)

literature <- utils::read.csv(project_file("data", "reference", "literature.csv"))
names(literature) <- c("Region", "Period", "Media", "Finding", "Citation")
literature[] <- lapply(literature, function(column) {
  gsub("&", "\\\\&", column, fixed = TRUE)
})
rows <- apply(literature, 1, function(row) paste(row, collapse = " & "))
lines <- c(
  "\\begin{table}[p]", "\\centering", "\\scriptsize",
  "\\caption{Racial distribution of perpetrators and victims in earlier television studies}",
  "\\label{tab:lit}",
  "\\begin{tabular}{p{.12\\linewidth}p{.09\\linewidth}p{.12\\linewidth}p{.40\\linewidth}p{.12\\linewidth}}",
  "\\toprule", "Region & Period & Media & Finding & Citation \\\\ ", "\\midrule",
  paste0(rows, " \\\\ "), "\\bottomrule", "\\end{tabular}", "\\end{table}"
)
writeLines(gsub("[ \t]+(?=\n|$)", "", lines, perl = TRUE), file.path(table_dir, "lit.tex"))
