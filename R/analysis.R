share_rows <- function(rows, by_year = FALSE) {
  keys <- if (by_year) c("series", "year") else "series"
  partitions <- split(rows, interaction(rows[keys], drop = TRUE, lex.order = TRUE))

  out <- lapply(partitions, function(part) {
    values <- list()
    for (role in c("victim", "criminal")) {
      for (dimension in c("gender", "race")) {
        groups <- if (dimension == "gender") {
          c("male", "female")
        } else {
          c("white", "black", "hispanic", "asian")
        }
        counts <- vapply(groups, function(group) {
          sum(part[[paste(role, group, sep = "_")]])
        }, numeric(1))
        total <- sum(counts)
        values[[paste(role, dimension, sep = "_")]] <- data.frame(
          series = part$series[1], year = if (by_year) part$year[1] else NA_integer_,
          crime_group = "all", role = role, dimension = dimension,
          group = groups, episode_n = nrow(part), count = as.numeric(counts),
          known_total = total,
          share_pct = if (total > 0) 100 * counts / total else NA_real_,
          stringsAsFactors = FALSE
        )
      }
    }
    do.call(rbind, values)
  })
  result <- do.call(rbind, out)
  rownames(result) <- NULL
  result
}

estimate_shares <- function(episodes) {
  aggregate <- share_rows(episodes)
  yearly <- share_rows(episodes, by_year = TRUE)
  list(aggregate = aggregate, yearly = yearly)
}
