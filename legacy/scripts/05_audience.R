"

Get audience numbers from data from:
https://github.com/hernamesbarbara/law_and_order/

"

# Set directory
setwd(basedir)
setwd("face_of_crime/")

# CI
root_dir <- "data/law_and_order/criminal_intent/episodes/"
ci_all  <- lapply(dir(root_dir), function(x) read.csv(paste0(root_dir, x))) 

# Audience numbers
aud_col <- sapply(ci_all, function(x) x[, grep("U.S.", names(x))])
aud_no  <- as.numeric(unlist(aud_col))

mean(aud_no, na.rm = T)
median(aud_no, na.rm = T)

# SVU
root_dir <- "data/law_and_order/svu/episodes/"
svu_all <- lapply(dir(root_dir), function(x) read.csv(paste0(root_dir, x))) 

# Audience numbers
aud_col <- sapply(svu_all, function(x) x[, grep("U.S.", names(x))])
aud_no  <- as.numeric(unlist(aud_col))

mean(aud_no, na.rm = T)
median(aud_no, na.rm = T)

# Original 
root_dir <- "data/law_and_order/original/episodes/"
or_all <- lapply(dir(root_dir), function(x) read.csv(paste0(root_dir, x))) 

# Audience numbers
aud_col <- sapply(or_all, function(x) x[, grep("U.S.", names(x))])
aud_no  <- as.numeric(unlist(aud_col))

mean(aud_no, na.rm = T)
median(aud_no, na.rm = T)
