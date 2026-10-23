"

Get the Law and Order data ready: 
load, parse and recode

In particular, parse the sex and gender cols. 

"

# Set directory
setwd(basedir)
setwd("face_of_crime/")

#
# Criminal Intent
#------------------------

# Read the data
lo_ci <- read.csv("data/ci/law_and_order_ci.csv")

# Change the col. names
names(lo_ci) <- c("season", "episode", "year", "title", "crime", "n_victims", "v_sex", "v_race", "n_criminals", "c_sex", "c_race", "notes")

# Parse sex into  n_c/v_male,  n_c/v_female, n_c/v_unknown_sex (last one: not done)
# Parse race into n_c/v_white, n_c/v_black, n_c/v_hispanic, n_c/v_asian, n_c/v_unknown_race (last one: not done)

parser <- function(in_col, needles) {

  in_col  <- tolower(in_col)

  splits   <- strsplit(in_col, ", ")

  res <- list() 

  for (i in needles) {
    res[[i]] <- sapply(splits, function(x) { 
                        comp <- i ==x | grepl(paste0(" ", i), x)
                        y    <- ifelse(sum(comp), x[comp], 0)
                        z    <- sapply(strsplit(as.character(y), " "), "[", 1)
                        as.numeric(ifelse(z == i, 1, z))
                        })
  }

  as.data.frame(res)
}

lo_ci[, c("n_v_male", "n_v_female")] <- parser(lo_ci$v_sex, needles = c("male", "female"))
lo_ci[, c("n_c_male", "n_c_female")] <- parser(lo_ci$c_sex, needles = c("male", "female"))

lo_ci[, c("n_v_white", "n_v_black", "n_v_hispanic", "n_v_asian")] <- parser(lo_ci$v_race, c("white", "black", "hispanic", "asian"))
lo_ci[, c("n_c_white", "n_c_black", "n_c_hispanic", "n_c_asian")] <- parser(lo_ci$c_race, c("white", "black", "hispanic", "asian"))

#
# Original
#------------------------

# Read the data
lo_or <- read.csv("data/lo/law_and_order_lo.csv")

# Change the col. names
names(lo_or) <- c("season", "episode", "year", "title", "crime", "n_victims", "v_sex", "v_race", "n_criminals", "c_sex", "c_race", "notes")

lo_or[, c("n_v_male", "n_v_female")] <- parser(lo_or$v_sex, c("male", "female"))
lo_or[, c("n_c_male", "n_c_female")] <- parser(lo_or$c_sex, c("male", "female"))

lo_or[, c("n_v_white", "n_v_black", "n_v_hispanic", "n_v_asian")] <- parser(lo_or$v_race, c("white", "black", "hispanic", "asian"))
lo_or[, c("n_c_white", "n_c_black", "n_c_hispanic", "n_c_asian")] <- parser(lo_or$c_race, c("white", "black", "hispanic", "asian"))

#
# SVU
#------------------------

# Season 1
lo_svu_1  <- read.csv("data/svu/law_and_order_svu_1.csv")    # Seasons 3--5
lo_svu_1$crime <- paste0(lo_svu_1$crime1, ";", lo_svu_1$crime2) # Concatenate crime 1 and 2
lo_svu_1$notes <- NA
lo_svu_1 <- subset(lo_svu_1, select = -c(crime1, crime2))

# Season 2
lo_svu_2  <- read.csv("data/svu/law_and_order_svu_2.csv")    # Seasons 3--5
lo_svu_2  <- subset(lo_svu_2, select = c("season", "episode", "year", "title", "crime", "n_victims", "v_sex", "v_race", "n_criminals", "c_sex", "c_race", "notes"))  

# Seasons 3--5
lo_svu_35  <- read.csv("data/svu/law_and_order_svu_3_5.csv")    # Seasons 3--5
lo_svu_35  <- subset(lo_svu_35, select = -c(Timestamp))  # Take out data in Timestamp

# Seasons 3--16
lo_svu_617 <- read.csv("data/svu/law_and_order_svu_6_17.csv")
lo_svu_617 <- subset(lo_svu_617, select = -c(Data.in.Google.forms)) # Take out data in goog_forms field

# Merge data
lo_svu <- rbind(lo_svu_1, lo_svu_2, lo_svu_35, lo_svu_617)

lo_svu[, c("n_v_male", "n_v_female")] <- parser(lo_svu$v_sex, c("male", "female"))
lo_svu[, c("n_c_male", "n_c_female")] <- parser(lo_svu$c_sex, c("male", "female"))

lo_svu[, c("n_v_white", "n_v_black", "n_v_hispanic", "n_v_asian")] <- parser(lo_svu$v_race, c("white", "black", "hispanic", "asian"))
lo_svu[, c("n_c_white", "n_c_black", "n_c_hispanic", "n_c_asian")] <- parser(lo_svu$c_race, c("white", "black", "hispanic", "asian"))
