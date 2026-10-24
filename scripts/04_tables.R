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
study <- paste0(
  literature$Citation, " \\newline ", literature$Region,
  " \\newline ", literature$Period
)
rows <- paste(study, literature$Media, literature$Finding, sep = " & ")
lines <- c(
  "\\begingroup", "\\footnotesize",
  paste0(
    "\\begin{longtable}{@{}",
    ">{\\raggedright\\arraybackslash}p{.23\\linewidth}",
    ">{\\raggedright\\arraybackslash}p{.15\\linewidth}",
    ">{\\raggedright\\arraybackslash}p{.56\\linewidth}@{}}"
  ),
  "\\caption{Racial Distribution of Perpetrators and Victims on Various Television Shows}\\label{tab:lit}\\\\",
  "\\toprule",
  "Study and setting & Media & Key relevant findings \\\\",
  "\\midrule", "\\endfirsthead",
  "\\caption[]{Racial Distribution of Perpetrators and Victims on Various Television Shows (continued)}\\\\",
  "\\toprule",
  "Study and setting & Media & Key relevant findings \\\\",
  "\\midrule", "\\endhead",
  "\\midrule", "\\endfoot",
  "\\bottomrule", "\\endlastfoot",
  paste0(rows, " \\\\"),
  "\\end{longtable}", "\\endgroup"
)
writeLines(gsub("[ \t]+(?=\n|$)", "", lines, perl = TRUE), file.path(table_dir, "lit.tex"))
