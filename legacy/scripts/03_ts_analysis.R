"

Law & Order, SVU, and CI

1. Gender and Race of Criminals and Victims over Time
2. Comparison to NCVS, UCR, and Census 

"

# Set directory
setwd(basedir)
setwd("face_of_crime/")

# Set library
library(dplyr)
library(magrittr)
library(tidyr)

library(xtable)
# Via grattan package which currently doesn't let pass arguments to xtable//Double header lines
source("scripts/00_print_2heading_xtable.R")

library(ggplot2)
library(directlabels)

# Execute data cleaner
source("scripts/01_get_data_ready.R")

# Merge
lo_ci$series  <- "Criminal Intent"
lo_svu$series <- "SVU"
lo_or$series  <- "Original"

lo_all <- rbind(lo_ci, lo_svu, lo_or)

# Add Census, UCR, Crime Victimization Data

# Read and modify headers of census
census        <- read.csv("data/census/census.csv")
names(census) <- c("year", "white_us", "black_us", "men_us", "white_ny", "black_ny", "men_ny")

# Read in NCVS
ncvs       <- read.csv("data/ncvs/ncvs.csv")

# Read in murder victim data
murder_victims <- read.csv("data/ucr/murder_victim_race_gender.csv")
murder_victims[, 2:4] <- sapply(murder_victims[, 2:4], function(x) as.numeric(gsub("%", "", x)))
names(murder_victims) <- tolower(names(murder_victims))

# UCR
ucr        <- read.csv("data/ucr/race_gender_criminals.csv")

# NY Data  
ny        <- read.csv("data/ny_enforcement/nyc_enforcement.csv")
names(ny) <- tolower(names(ny))
ny        <- as.data.frame(lapply(ny, function(x) as.numeric(gsub("%", "", x))))

# Victims by Gender
# ----------------------------

out <- lo_all %>%
  group_by(series, year) %>%
  summarise(male = sum(n_v_male, na.rm = T),
  	        female = sum(n_v_female, na.rm = T),
  	        pfemale = female*100/sum(male, female))

# Spread by series
w_out <- out[, c("pfemale", "series", "year")] %>% spread(series, pfemale)

# Append data
all_out_v_gender <- w_out %>%
  left_join(ncvs[, c("year", "serious_violent_victimization_male", "rape_sexual_assault_male", "aggravated_assault_male")], by = "year") %>%
  left_join(murder_victims[,c("year", "murder_victim_men")], by = "year") %>%
  left_join(census[, c("year", "men_us", "men_ny")], by = "year")

# Convert Percent Men to Percent Women
all_out_v_gender[, 5:length(all_out_v_gender)] <- 100 - all_out_v_gender[, 5:length(all_out_v_gender)]

# Aggregate Numbers 
colMeans(all_out_v_gender[, 5:9], na.rm = T)

# Add % Sign
#all_out_v_gender[,2:length(all_out_v_gender)] <- paste0(all_out_v_gender[,2:length(all_out_v_gender)], "%")

# Rename the cols.
renames <- c(year = "Year", 
  "Criminal Intent" = "Law and Order__Criminal Intent",
  Original = "Law and Order__Original",
  SVU = "Law and Order__SVU",
  serious_violent_victimization_male = "NCVS__Serious Violent Victimization",
  rape_sexual_assault_male           = "NCVS__Rape or Sexual Assault",
  aggravated_assault_male            = "NCVS__Aggravated Violent Victimization",
  murder_victim_men                  = "UCR__Murder Victims",
  men_us                             = "Census__US",
  men_ny                             = "Census__NY"
)
names(all_out_v_gender) <- renames[match(names(all_out_v_gender), names(renames))]

print_2heading_xtable(all_out_v_gender, separator = "__",
		digits = c(0, 0, rep(1, 9)),
		caption = "Share of Female Victims in Law \\& Order and the Real World, and Share of Women in the Population",
	  	label = "tab:v_sex",
		caption.placement = "top",
		size = "\\tiny", 
		heading_command = NULL,
		xtable.align = c("l", rep("c", 10)),
		sanitize.text.function = function(x){x},
	    table.placement = "!htb",
	    file = "tabs/v_gender.tex")

# Plot 1a
# Victims by Gender

#----------------

cust_theme <- theme_minimal() +
  theme(panel.grid.major   = element_line(color="#e7e7e7",  linetype = "dotted"),
	  panel.grid.minor =  element_blank(),
	  legend.position  = "none",
	  axis.title   = element_text(size = 10, color = "#555555"),
	  axis.text    = element_text(size = 8, color = "#555555"),
	  axis.ticks.y = element_blank(),
	  axis.title.x = element_text(vjust = -1),
	  axis.title.y = element_text(vjust = 1),
	  axis.ticks.x = element_line(color = "#e7e7e7",  linetype = "dotted", size = .2),
	  plot.margin = unit(c(0, 1, .5, .5), "cm"))

#---------------------------

p <- ggplot(out, aes(x = year, y = pfemale, color = series)) +
  geom_point(pch = 16, size = 3) +
  geom_line(lty = "dotted", alpha = .7) +
  scale_y_continuous(name = "Percentage of Female Victims", limits = c(0, 100), breaks = seq(0, 100, 10), labels = paste0(seq(0, 100, 10), "%")) +
  scale_x_continuous(name = "", limits = c(1990, 2016), breaks = seq(1990, 2020, 5), labels = seq(1990, 2020, 5)) +
  labs(color = NULL) +
  cust_theme

direct.label(p, list(last.points, cex = .8, alpha = 1, hjust = 0, vjust = -.75))

ggsave("figs/all_victims_by_gender_ts.pdf", dpi = 450, width = 7.5)


# Perpetrators by Gender
# ---------------------------------

out <- lo_all %>%
  group_by(series, year) %>%
  summarise(male = sum(n_c_male, na.rm = T), female = sum(n_c_female, na.rm = T), pfemale = female*100/sum(male, female))

# Spread by series
w_out <- out[, c("pfemale", "series", "year")] %>% spread(series, pfemale)

# Append data
all_out_c_gender <- w_out %>%
  left_join(ucr[, c("year", "all_crime_perc_men", "violent_crime_perc_men", "homicides_perc_men", "rape_perc_men", "assault_perc_men")], by = "year") %>%
  left_join(census[, c("year", "men_us", "men_ny")], by = "year")

# Convert Percent Men to Percent Women
all_out_c_gender[, 5:length(all_out_c_gender)] <- 100 - all_out_c_gender[, 5:length(all_out_c_gender)]

renames <- c(year = "Year",
  "Criminal Intent" = "Law and Order__Criminal Intent",
  Original = "Law and Order__Original",
  SVU = "Law and Order__SVU",
  all_crime_perc_men      = "UCR__All Crime",
  violent_crime_perc_men  = "UCR__Violent Crime",
  homicides_perc_men      = "UCR__Homicides",
  rape_perc_men           = "UCR__Rape",
  assault_perc_men        = "UCR__Assault",
  men_us                  = "Census__US",
  men_ny                  = "Census__NY"
)

names(all_out_c_gender) <- renames[match(names(all_out_c_gender), names(renames))]

# Aggregate Numbers 
colMeans(all_out_c_gender[, 5:9], na.rm = T)

print_2heading_xtable(all_out_c_gender, 
	separator = "__",
    digits = c(0, 0, rep(1, 10)),
	caption = "Share of Female Criminals in Law \\& Order, and the Real World, and Share of Women in the Population",
	label = "tab:c_sex",
	caption.placement = "top",
	size = "\\tiny", 
	heading_command = NULL,
	xtable.align = c("l", rep("c", 11)),
	sanitize.text.function = function(x){x},
	table.placement = "!htb",
	file = "tabs/c_gender.tex")


# Plot 1b
# CI Perpetrators by Gender

p <- ggplot(out, aes(x = year, y = pfemale, color = series)) +
  geom_point(pch = 16, alpha = .8, size = 3) +
  geom_line(lty = "dotted", alpha = .7) +
  scale_y_continuous(name = "Percentage of Female Criminals", limits = c(0, 100), breaks = seq(0, 100, 10), labels = paste0(seq(0, 100, 10), "%")) +
  scale_x_continuous(name = "", limits = c(1990, 2016), breaks = seq(1990, 2020, 5), labels = seq(1990, 2020, 5)) +
  labs(color = NULL) +
  cust_theme

direct.label(p, list(last.points, cex = .8, alpha = 1, hjust = 0, vjust = -.75))

ggsave("figs/all_criminals_by_gender_ts.pdf", dpi = 450, width = 7.5)

# Victims by Race
# ---------------------------------

out <- lo_all %>%
  group_by(series, year) %>%
  summarise(white = sum(n_v_white, na.rm = T),
	      black = sum(n_v_black, na.rm = T),
	      hispanic = sum(n_c_hispanic, na.rm = T),
	      asian = sum(n_v_asian, na.rm = T),
	      pblack = black*100/sum(white, black, hispanic, asian))

# Spread by series
w_out <- out[, c("pblack", "series", "year")] %>% spread(series, pblack)

# Append data
all_out_v_race <- w_out %>%
  left_join(ncvs[, c("year", "serious_violent_victimization_black", "rape_sexual_assault_black", "aggravated_assault_black")], by = "year") %>%
  left_join(ny[,  c("year", "homicides_black_victim", "rapes_black_victim", "assaults_black_victim", "robberies_black_victim")], by = "year") %>%
  left_join(murder_victims[, c("year", "murder_victim_black")], by = "year") %>%
  left_join(census[, c("year", "black_us", "black_ny")], by = "year")

renames <- c(year = "Year", 
  "Criminal Intent" = "Law and Order__Criminal Intent",
  Original = "Law and Order__Original",
  SVU = "Law and Order__SVU",
  serious_violent_victimization_black = "NCVS__Serious Violent Victimization",
  rape_sexual_assault_black           = "NCVS__Rape or Sexual Assault",
  aggravated_assault_black            = "NCVS__Aggravated Violent Victimization",
  murder_victim_black                 = "UCR__Murder Victims",
  homicides_black_victim              = "NYPD__Homicides",
  rapes_black_victim                  = "NYPD__Rape",
  assaults_black_victim               = "NYPD__Assault",
  robberies_black_victim              = "NYPD__Robbery",
  black_us                            = "Census__US",
  black_ny                            = "Census__NY"
)

names(all_out_v_race) <- renames[match(names(all_out_v_race), names(renames))]

# Aggregate Numbers 
colMeans(all_out_v_race[, 5:8], na.rm = T)

print_2heading_xtable(all_out_v_race,
	separator = "__",
	digits = c(0, 0, rep(1,13)),
	caption = "Share of Black Victims in Law \\& Order, and the Real World, and Share of Blacks in the Population", 
	label = "tab:v_race",
	caption.placement = "top",
	size = "\\tiny",
	floating.environment = "sidewaystable",
	heading_command = NULL,
	xtable.align = c("l", rep("c", 14)),
	sanitize.text.function = function(x){x},
	table.placement = "!htb",
	file = "tabs/v_race.tex")

# Plot 2b
# CI Victims by Race

p <- ggplot(out, aes(x = year, y = pblack, color = series)) +
  geom_point(pch = 16, alpha = .8, size = 3) +
  geom_line(lty = "dotted", alpha = .7) +
  scale_y_continuous(name = "Percentage of Black Victims", limits = c(0, 100), breaks = seq(0, 100, 10), labels = paste0(seq(0, 100, 10), "%")) +
  scale_x_continuous(name = "", limits=c(1990, 2016), breaks = seq(1990, 2020, 5), labels = seq(1990, 2020, 5)) +
  labs(color = NULL) +
  cust_theme

direct.label(p, list(last.points, cex = .8, alpha = 1, hjust = 0, vjust = -.75))

ggsave("figs/all_victims_by_race_ts.pdf", dpi = 450, width = 7.5)

# Perpetrators by Race
# ---------------------------------

out <- lo_all %>%
  group_by(series, year) %>%
  summarise(white = sum(n_c_white, na.rm = T),
	      black = sum(n_c_black, na.rm = T),
	      hispanic = sum(n_c_hispanic, na.rm = T),
	      asian = sum(n_v_asian, na.rm = T),
	      pblack = black*100/sum(white, black, hispanic, asian))

# Spread by series
w_out <- out[,c("pblack", "series", "year")] %>% spread(series, pblack)

# Append data
all_out_c_race <- w_out %>%
  left_join(ucr[, c("year", "all_crime_perc_black", "violent_crime_perc_black", "homicides_perc_black", "rape_perc_black", "assault_perc_black")], by = "year") %>%
  left_join(ny[,  c("year", "homicides_black_suspect", "rapes_black_suspect", "assaults_black_suspect", "robberies_black_suspect")], by = "year") %>%
  left_join(census[, c("year", "black_us", "black_ny")], by = "year") 

renames <- c(year = "Year", 
  "Criminal Intent" = "Law and Order__Criminal Intent",
  Original = "Law and Order__Original",
  SVU = "Law and Order__SVU",
  all_crime_perc_black      = "UCR__All Crime",
  violent_crime_perc_black  = "UCR__Violent Crime",
  homicides_perc_black      = "UCR__Homicides",
  rape_perc_black           = "UCR__Rape",
  assault_perc_black        = "UCR__Assault",
  homicides_black_suspect   = "NYPD__Homicides",
  rapes_black_suspect       = "NYPD__Rape",
  assaults_black_suspect    = "NYPD__Assault",
  robberies_black_suspect   = "NYPD__Robbery",
  black_us                  = "Census__US",
  black_ny                  = "Census__NY"
)

names(all_out_c_race) <- renames[match(names(all_out_c_race), names(renames))]

print_2heading_xtable(all_out_c_race,
	separator = "__",
    digits = c(0, 0, rep(1, 14)),
	caption = "Share of Black Criminals in Law \\& Order, and the Real World, and Share of Blacks in the Population", 
	label = "tab:c_race",
	caption.placement = "top",
	size = "\\tiny", 
	heading_command = NULL,
	xtable.align = c("l", rep("c", 15)),
	sanitize.text.function = function(x){x},
	table.placement = "!htb",
	file = "tabs/c_race.tex")

# Plot 2b
# CI Perpetrators  by Race

p <- ggplot(out, aes(x = year, y = pblack, color = series)) +
  geom_point(pch = 16, alpha = .8, size = 3) +
  geom_line(lty = "dotted", alpha = .7) +
  scale_y_continuous(name = "Percentage of Black Criminals", limits = c(0, 100), breaks = seq(0, 100, 10), labels = paste0(seq(0, 100, 10), "%")) +
  scale_x_continuous(name = "", limits = c(1990, 2016), breaks = seq(1980, 2020, 5), labels = seq(1980, 2020, 5)) +
  labs(color = NULL) +
  cust_theme

direct.label(p, list(last.points, cex = .8, alpha = 1, hjust = 0, vjust = -.75))

ggsave("figs/all_criminals_by_race_ts.pdf", dpi = 450, width = 7.5)
