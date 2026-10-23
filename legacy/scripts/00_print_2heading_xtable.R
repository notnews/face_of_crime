"

Amended using the base version from:
https://github.com/HughParsonage/grattan/

"

print_2heading_xtable <- function(.data,
                                  caption = NULL,
                                  label = NULL,
                                  digits = NULL,
                                  separator = "__",
                                  xtable.align = NULL,
                                  booktabs = TRUE,
                                  heading_command = "\\textbf", ...){
  orig_names <- names(.data)
  if (!any(grepl(separator, orig_names))){
    stop("No separator found in column names, so there is no point in using this function.
         Make sure you have specified the right separator; otherwise, just use print.xtable().")
  }

  if (any(c("add.to.row", "include.colnames", "include.rownames") %in% names(list(...)))){
    stop("You should not pass add.to.row, include.colnames, or include.rownames to print.xtable() via this function.")
  }

  split_names <-  grep(separator, orig_names, value = TRUE)
  split_positions <- grep(separator, orig_names, value = FALSE)

  # get the names before the separator
  top_headers <- gsub(paste0("^(.*)", separator, ".*$"), "\\1", split_names)
  # Where in the original table is there a new top header?

  orig_names_no_suffix <-
    gsub(paste0("^(.*)", separator, ".*$"), paste0("\\1", separator), orig_names)

  # For cmidrule{}
  position_of_header_instance <-
    # Need to test first column
    which(orig_names_no_suffix == dplyr::lead(orig_names_no_suffix) &
            (orig_names_no_suffix != dplyr::lag(orig_names_no_suffix) | is.na(dplyr::lag(orig_names_no_suffix))))

  position_of_header_final <-
    # Need to test final column
    which((orig_names_no_suffix != dplyr::lead(orig_names_no_suffix) | is.na(dplyr::lead(orig_names_no_suffix))) &
            orig_names_no_suffix == dplyr::lag(orig_names_no_suffix))

  if (length(position_of_header_instance) != length(position_of_header_final)){
    stop("This is a bug. Sorry. Please provide your data frame to the grattan package maintainer.")
  }

  double_row_column_names <-
    rbind(gsub(paste0("^(.*)", separator, "(.*)$"), "\\1", orig_names),
          gsub(paste0("^(.*)", separator, "(.*)$"), "\\2", orig_names))

  # factor etc in table to preserve order
  top_headers_widths <-
    as.data.frame(table(factor(double_row_column_names[1, ], levels = unique(double_row_column_names[1, ]))))

  first_row <-
    unique(double_row_column_names[1, ])

  first_row_formatted <-
    paste0(heading_command, "{", first_row, "}")

  top_row <- character(length(first_row))

  # Could do paste0() directly but decided that it would
  # avoid the point which is to add \multicolumn only to the rows that call for it.
  for (ii in seq_along(first_row)){
    if (first_row[ii] %in% top_headers){
      top_row[ii] <- paste0("\\multicolumn{", top_headers_widths$Freq[ii], "}{c}{", first_row_formatted[ii], "}")
    }
  }
  rm(ii)

  for_latex_top_row <-
    paste0(paste0(top_row, collapse = " & "), "\\\\")

  if (booktabs){
    # (lr) to avoid cmidrule touching adjacent groups
    between_row <- paste0("\\cmidrule(lr){",  position_of_header_instance, "-", position_of_header_final, "}")
  } else {
    between_row <- paste0("\\cline{",  position_of_header_instance, "-", position_of_header_final, "}")
  }
  for_latex_between_row <-
    paste0(paste0(between_row, collapse = ""))

  for_latex_second_row <-
    paste0(heading_command, "{", double_row_column_names[2, ], "}")

  for_latex_second_row <-
    paste0(paste0(for_latex_second_row, collapse = " & "), "\\\\")

  addtorow <- list()
  addtorow$pos <- list(0, 0, 0)
  addtorow$command <-
    paste0(paste0(c(for_latex_top_row, for_latex_between_row, for_latex_second_row)), "\n")

  xtable::print.xtable(xtable::xtable(.data,
                         align = xtable.align,
                         caption = caption,
                         digits = digits,
                         label = label),
                         type = "latex",
                       add.to.row = addtorow,
                       include.colnames = FALSE,
                       include.rownames = FALSE,
                       booktabs = booktabs,
                       ...)

}
