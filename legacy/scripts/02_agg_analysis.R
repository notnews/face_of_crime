"

Law & Order, SVU, and CI

1. Gender and Race of Criminals and Victims (Aggregated)
2. Comparison to NCVS, UCR, and Census 

"

# Set directory
setwd(basedir)
setwd("face_of_crime/")

# Set library
library(ggplot2)
library(dplyr)
library(reshape2)

# Execute data cleaner
source("scripts/01_get_data_ready.R")

# Merge
# 
lo_ci$series  <- "Criminal Intent"
lo_svu$series <- "SVU"
lo_or$series  <- "Original"

lo_all <- rbind(lo_ci, lo_svu, lo_or)

# Total shows, n_victims, n_criminals
# -----------------------------------------
nrow(lo_all)
sum(as.numeric(lo_all$n_victims), na.rm = T)
sum(as.numeric(lo_all$n_criminals), na.rm = T)

# What kind of crime 
# ---------------------------
lo_all$rape    <- grepl("rape",    tolower(lo_all$crime))
lo_all$murder  <- grepl("murder",  tolower(lo_all$crime))
lo_all$assault <- grepl("assault", tolower(lo_all$crime))

sum(lo_all$rape | lo_all$murder)
sum(lo_all$rape | lo_all$murder | lo_all$assault)

# Split by series 
table(lo_all$murder, lo_all$series)
table(lo_all$rape,   lo_all$series)

# Split by crime 
lo_rape     <- lo_all[lo_all$rape == 1, ]
lo_murder   <- lo_all[lo_all$murder == 1, ]
lo_mrdraslt <- lo_all[lo_all$murder == 1 | lo_all$assault == 1, ]

# Add Census, UCR, Crime Victimization Data
#----------------------------------------------
# Read and modify headers of census
census        <- read.csv("data/census/census.csv")
names(census) <- c("year", "white_us", "black_us", "men_us", "white_ny", "black_ny", "men_ny")
census_means  <- colMeans(census)

# Read in NCVS
ncvs       <- read.csv("data/ncvs/ncvs.csv")
ncvs_means <- colMeans(ncvs)

# NCVS Hispanic 
ncvs_hisp       <- read.csv("data/ncvs/ncvs_hispanic.csv")
ncvs_hisp_means <- colMeans(ncvs_hisp)

# Read in murder victim data
murder_victims        <- read.csv("data/ucr/murder_victim_race_gender.csv")
murder_victims[, 2:4]  <- sapply(murder_victims[, 2:4], function(x) as.numeric(gsub("%", "", x)))
names(murder_victims) <- tolower(names(murder_victims))
murder_v_means        <- colMeans(murder_victims)

# UCR
ucr        <- read.csv("data/ucr/race_gender_criminals.csv")
ucr_means  <- colMeans(ucr)

# UCR Hispanic 
ucr_hisp        <- read.csv("data/ucr/race_gender_criminals_hispanic.csv")
ucr_hisp_means  <- colMeans(ucr_hisp, na.rm = T)

# NY Data  
ny        <- read.csv("data/ny_enforcement/nyc_enforcement.csv")
names(ny) <- tolower(names(ny))
ny        <- as.data.frame(lapply(ny, function(x) as.numeric(gsub("%", "", x))))
ny_means  <- colMeans(ny, na.rm = T)

# Custom theme
#-----------------

cust_theme <- theme_minimal() +
  theme(panel.grid.major = element_line(color="#e1e1e1",  linetype = "dotted"),
	  panel.grid.minor = element_blank(),
	  legend.position  ="bottom",
	  legend.key      = element_blank(),
	  legend.key.width = unit(1, "cm"),
	  axis.title   = element_text(size = 10, color = "#555555"),
	  axis.text    = element_text(size = 10, color = "#555555"),
	  axis.ticks.y = element_blank(),
	  axis.title.x = element_text(vjust = -1, margin = margin(10, 0, 0, 0)),
	  axis.title.y = element_text(vjust = 1),
	  axis.ticks   = element_line(color = "#e3e3e3", size = .2),
	  plot.margin = unit(c(0, 1, 0, 0), "cm"))


# Plot 1a
# --------------------------

# Victims by Gender in shows where one of the crimes was rape 
out_rape <- lo_rape %>%
  group_by(series) %>%
  summarise(male = sum(n_v_male, na.rm = T),
  	       female = sum(n_v_female, na.rm = T),
  	       pfemale = female*100/sum(male, female))
rout_rape <- out_rape[3, c("series", "pfemale")] # as number of rapes portrayed in other shows not large enough

# Victims by Gender in shows where one of the crimes was murder
out_murder <- lo_murder %>%
  group_by(series) %>%
  summarise(male = sum(n_v_male, na.rm = T),
  	        female = sum(n_v_female, na.rm = T),
  	        pfemale = female*100/sum(male, female))
rout_murder <- out_murder[, c("series", "pfemale")]

# Victims by gender
out <- lo_all %>%
  group_by(series) %>%
  summarise(male = sum(n_v_male, na.rm = T),
  	       female = sum(n_v_female, na.rm = T),
  	       pfemale = female*100/sum(male, female))
rout <- out[, c("series", "pfemale")]

# UCR and NCVS
ucr_v_sex  <- data.frame(series = "UCR",  pfemale = 100 - murder_v_means["murder_victim_men"])
ncvs_v_sex <- data.frame(series = "NCVS", pfemale = 100 - ncvs_means[c("rape_sexual_assault_male", "serious_violent_victimization_male")])

# All/Murder 
rout2 <- cbind(rbind(rout, rout_murder, rout_rape, ucr_v_sex, ncvs_v_sex), crime = c(rep("All", 3), rep("Murder", 3), "Rape", "Murder","Rape", "Serious Violent Victimization"))
rout2$series <- factor(rout2$series, levels = c("UCR", "NCVS", "SVU", "Criminal Intent", "Original"))

# Plot
ggplot(rout2, aes(series, pfemale, color = crime)) +
  geom_point(pch = 16, size = 3, alpha = .55) + #position=position_dodge(.1), 
  scale_colour_manual(values = c("#aaaaaa", "#5628a6", "#56a628", "#a65628"), guide = guide_legend(title = "")) +
  coord_flip() +
  scale_x_discrete(expand = c(.3, 1)) +
  scale_y_continuous(name = "Percentage of Female Victims", limits = c(0, 100), breaks = seq(0, 100, 10), labels = paste0(seq(0, 100, 10), "%")) +
  xlab("") +
  cust_theme

ggsave("figs/all_victims_by_gender.pdf", scale = .8)


# Plot 1b
# ---------------------------------

# Criminals by Gender in shows where one of the crimes was rape 
out_rape <- lo_rape %>%
  group_by(series) %>%
  summarise(male = sum(n_c_male, na.rm = T),
  	       female = sum(n_c_female, na.rm = T),
  	       pfemale = female*100/sum(male, female))
rout_rape <- out_rape[3, c("series", "pfemale")] # as number of rapes portrayed in other shows not large enough

# Criminals by Gender in shows where one of the crimes was murder
out_murder <- lo_murder %>%
  group_by(series) %>%
  summarise(male = sum(n_c_male, na.rm = T),
  	        female = sum(n_c_female, na.rm = T),
  	        pfemale = female*100/sum(male, female))
rout_murder <- out_murder[, c("series", "pfemale")]

# Criminals by Gender
out <- lo_all %>%
  group_by(series) %>%
  summarise(male = sum(n_c_male, na.rm = T),
  	       female = sum(n_c_female, na.rm = T),
  	       pfemale = female*100/sum(male, female))
rout <- out[, c("series", "pfemale")]

# UCR 
ucr_c_sex <- data.frame(series = "UCR",  pfemale = 100 - ucr_means[c("all_crime_perc_men", "homicides_perc_men", "rape_perc_men")])

# All/Rape/Murder 
rout2 <- cbind(rbind(rout, rout_murder, rout_rape, ucr_c_sex), crime = c(rep("All", 3), rep("Murder", 3), "Rape", c("All", "Murder", "Rape")))
rout2$series <- factor(rout2$series, levels = c("UCR", "NCVS", "SVU", "Criminal Intent", "Original"))

# Plot
ggplot(rout2, aes(series, pfemale, color = crime)) +
  geom_point(pch = 16, size = 3, alpha = .55) +
  scale_colour_manual(values = c("#aaaaaa","#5628a6", "#56a628"), guide = guide_legend(title = "")) +
  coord_flip() +
  scale_x_discrete(expand = c(.3, 1)) +
  scale_y_continuous(name = "Percentage of Female Criminals", limits = c(0, 100), breaks = seq(0, 100, 10), labels = paste0(seq(0, 100, 10), "%")) +
  xlab("") +
  cust_theme

ggsave("figs/all_criminals_by_gender.pdf", scale = .8)

# Plot 2a
# -------------------

# Victims by Race in shows where one of the crimes was rape 
out_rape <- lo_rape %>%
  group_by(series) %>%
  summarise(white = sum(n_v_white, na.rm = T),
  	        black = sum(n_v_black, na.rm = T),
  	        hispanic = sum(n_v_hispanic, na.rm = T),
  	        asian = sum(n_v_asian, na.rm = T),
  	        pblack = black*100/sum(white, black, hispanic, asian))
rout_rape <- out_rape[3, c("series", "pblack")] # as number of rapes portrayed in other shows not large enough

# Victims by Race in shows where one of the crimes was murder
out_murder <- lo_murder %>%
  group_by(series) %>%
  summarise(white = sum(n_v_white, na.rm = T),
	      black = sum(n_v_black, na.rm = T),
	      hispanic = sum(n_v_hispanic, na.rm = T),
	      asian = sum(n_v_asian, na.rm = T),
	      pblack = black*100/sum(white, black, hispanic, asian))
rout_murder <- out_murder[, c("series", "pblack")]

# Victims by Race
out <- lo_all %>%
  group_by(series) %>%
  summarise(white = sum(n_v_white, na.rm = T),
  	        black = sum(n_v_black, na.rm = T),
  	        hispanic = sum(n_v_hispanic, na.rm = T),
  	        asian = sum(n_v_asian, na.rm = T),
  	        pblack = black*100/sum(white, black, hispanic, asian))
rout <-  out[, c("series", "pblack")]

# UCR and NCVS and NY 
ucr_v_race  <- data.frame(series = "UCR",  pblack = murder_v_means["murder_victim_black"])
ncvs_v_race <- data.frame(series = "NCVS", pblack = ncvs_means[c("rape_sexual_assault_black", "serious_violent_victimization_black")])
ny_v_race   <- data.frame(series = "NYPD", pblack = ny_means[c("homicides_black_victim", "rapes_black_victim")])

# All/Rape/Murder 
rout2 <- cbind(rbind(rout, rout_murder, rout_rape, ucr_v_race, ncvs_v_race, ny_v_race), crime = c(rep("All", 3), rep("Murder", 3), "Rape", "Murder", "Rape", "Serious Violent Victimization", "Murder", "Rape"))
rout2$series <- factor(rout2$series, levels = c("NYPD", "UCR", "NCVS", "SVU", "Criminal Intent", "Original"))

ggplot(rout2, aes(series, pblack, color = crime)) +
  geom_point(pch = 16, size = 3, alpha = .55) +
  scale_colour_manual(values = c("#aaaaaa","#5628a6", "#56a628", "#a65628"), guide = guide_legend(title = "")) +
  coord_flip() +
  scale_x_discrete(expand = c(.3, 1)) +
  scale_y_continuous(name = "Percentage of Black Victims", limits = c(0, 100), breaks = seq(0, 100, 10), labels = paste0(seq(0, 100, 10), "%")) +
  xlab("") +
  cust_theme

ggsave("figs/all_victims_by_race.pdf", scale = .8)

# Plot 2a/SI: Hispanics 
# ---------------------------

# Hispanic victims of rape
out_rape <- lo_rape %>%
  group_by(series) %>%
  summarise(white = sum(n_v_white, na.rm = T),
  	        black = sum(n_v_black, na.rm = T),
  	        hispanic = sum(n_v_hispanic, na.rm = T),
  	        asian = sum(n_v_asian, na.rm = T),
  	        phispanic = hispanic*100/sum(white, black, hispanic, asian))
rout_rape <- out_rape[3, c("series", "phispanic")] # as number of rapes portrayed in other shows not large enough

# Hispanic Victims in shows where one of the crimes was murder
out_murder <- lo_murder %>%
  group_by(series) %>%
  summarise(white = sum(n_v_white, na.rm = T),
  	        black = sum(n_v_black, na.rm = T),
  	        hispanic = sum(n_v_hispanic, na.rm = T),
  	        asian = sum(n_v_asian, na.rm = T),
  	        phispanic = hispanic*100/sum(white, black, hispanic, asian))
rout_murder <- out_murder[, c("series", "phispanic")]

out <- lo_all %>%
  group_by(series) %>%
  summarise(white = sum(n_v_white, na.rm = T),
	      black = sum(n_v_black, na.rm = T),
	      hispanic = sum(n_v_hispanic, na.rm=T),
	      asian = sum(n_v_asian, na.rm = T),
	      phispanic = hispanic*100/sum(white, black, hispanic, asian))
rout <-  out[, c("series", "phispanic")]

ny_v_race     <- data.frame(series = "NYPD", phispanic = ny_means[c("homicides_hispanic_victim", "rapes_hispanic_victim")])
ncvs_v_race   <- data.frame(series = "NCVS", phispanic = ncvs_hisp_means[c("rape_hispanic", "serious_violent_victimization_hispanic")])

# All/Rape/Murder Hispanic 
rout2 <- cbind(rbind(rout, rout_murder, rout_rape, ny_v_race, ncvs_v_race), crime = c(rep("All", 3), rep("Murder", 3), "Rape", "Murder", "Rape", "Rape", "Serious Violent Victimization"))
rout2$series <- factor(rout2$series, levels = c("NYPD", "NCVS", "SVU", "Criminal Intent", "Original"))

ggplot(rout2, aes(series, phispanic, color = crime)) +
  geom_point(pch = 16, size = 3, alpha = .55) +
  scale_colour_manual(values = c("#aaaaaa","#5628a6", "#56a628", "#a65628"), guide = guide_legend(title = "")) +
  coord_flip() +
  scale_x_discrete(expand = c(.3, 1)) +
  scale_y_continuous(name = "Percentage of Hispanic Victims", limits = c(0, 100), breaks = seq(0, 100, 10), labels = paste0(seq(0, 100, 10), "%")) +
  xlab("") +
  cust_theme

ggsave("figs/all_victims_by_race_hispanic.pdf", scale = .8)

# Plot 2b
# --------------------------

# Criminals  by Race in shows where one of the crimes was rape 
out_rape <- lo_rape %>%
  group_by(series) %>%
  summarise(white = sum(n_c_white, na.rm = T),
	      black = sum(n_c_black, na.rm = T),
	      hispanic = sum(n_c_hispanic, na.rm = T),
	      asian = sum(n_v_asian, na.rm = T),
	      pblack = black*100/sum(white, black, hispanic, asian))
rout_rape <- out_rape[3, c("series", "pblack")] # as number of rapes portrayed in other shows not large enough

# Criminals  by Race in shows where one of the crimes was murder
out_murder <- lo_murder %>%
  group_by(series) %>%
  summarise(white = sum(n_c_white, na.rm = T),
	      black = sum(n_c_black, na.rm = T),
	      hispanic = sum(n_c_hispanic, na.rm = T),
	      asian = sum(n_v_asian, na.rm = T),
	      pblack = black*100/sum(white, black, hispanic, asian))
rout_murder <- out_murder[, c("series", "pblack")]

# Criminals  by Race
out <- lo_all %>%
  group_by(series) %>%
  summarise(white = sum(n_c_white, na.rm = T),
  	        black = sum(n_c_black, na.rm = T),
  	        hispanic = sum(n_c_hispanic, na.rm = T),
  	        asian = sum(n_v_asian, na.rm = T),
  	        pblack = black*100/sum(white, black, hispanic, asian))
rout <- out[, c("series", "pblack")]

# UCR 
ucr_c_race <- data.frame(series = "UCR",  pblack = ucr_means[c("all_crime_perc_black", "homicides_perc_black", "rape_perc_black")])
ny_c_race  <- data.frame(series = "NYPD", pblack=ny_means[c("homicides_black_suspect", "rapes_black_suspect")])

# All/Rape/Murder 
rout2 <- cbind(rbind(rout, rout_murder, rout_rape, ucr_c_race, ny_c_race), crime = c(rep("All",3), rep("Murder", 3), "Rape", c("All", "Murder","Rape"), "Murder", "Rape"))
rout2$series <- factor(rout2$series, levels = c("NYPD", "UCR", "NCVS", "SVU", "Criminal Intent", "Original"))

ggplot(rout2, aes(series, pblack, color = crime)) +
  geom_point(pch = 16, size = 3, alpha = .55) +
  scale_colour_manual(values = c("#aaaaaa","#5628a6", "#56a628"), guide = guide_legend(title = "")) +
  coord_flip() +
  scale_x_discrete(expand=  c(.3, 1)) +
  scale_y_continuous(name = "Percentage of Black Criminals", limits = c(0, 100), breaks = seq(0, 100, 10), labels = paste0(seq(0, 100, 10), "%")) +
  xlab("") +
  cust_theme

ggsave("figs/all_criminals_by_race.pdf", scale = .8)

# Plot 2b/SI/Hispanics 
# --------------

# Criminals  by Race in shows where one of the crimes was rape 
out_rape <- lo_rape %>%
  group_by(series) %>%
  summarise(white = sum(n_c_white, na.rm = T),
  	        black = sum(n_c_black, na.rm = T),
  	        hispanic = sum(n_c_hispanic, na.rm = T),
  	        asian = sum(n_v_asian, na.rm = T),
  	        phispanic = hispanic*100/sum(white, black, hispanic, asian))
rout_rape <- out_rape[3, c("series", "phispanic")] # as number of rapes portrayed in other shows not large enough

# Criminals  by Race in shows where one of the crimes was murder
out_murder <- lo_murder %>%
  group_by(series) %>%
  summarise(white = sum(n_c_white, na.rm = T),
  	        black = sum(n_c_black, na.rm = T),
  	        hispanic = sum(n_c_hispanic, na.rm = T),
  	        asian = sum(n_v_asian, na.rm = T),
  	        phispanic = hispanic*100/sum(white, black, hispanic, asian))
rout_murder <- out_murder[, c("series", "phispanic")]

# Criminals  by Race
out <- lo_all %>%
  group_by(series) %>%
  summarise(white = sum(n_c_white, na.rm = T),
  	        black = sum(n_c_black, na.rm = T),
  	        hispanic = sum(n_c_hispanic, na.rm = T),
  	        asian = sum(n_v_asian, na.rm = T),
  	        phispanic = hispanic*100/sum(white, black, hispanic, asian))
rout <- out[, c("series", "phispanic")]

# UCR 
ucr_c_race  <- data.frame(series = "UCR",  phispanic = ucr_hisp_means[c("all_crime_perc_hispanic", "homicides_perc_hispanic", "rape_perc_hispanic")])
ny_c_race   <- data.frame(series = "NYPD", phispanic = ny_means[c("homicides_hispanic_suspect", "rapes_hispanic_suspect")])

# All/Rape/Murder 
rout2 <- cbind(rbind(rout, rout_murder, rout_rape, ucr_c_race, ny_c_race), crime = c(rep("All", 3), rep("Murder", 3), "Rape", c("All", "Murder", "Rape"), "Murder", "Rape"))
rout2$series <- factor(rout2$series, levels = c("NYPD", "UCR", "NCVS", "SVU", "Criminal Intent", "Original"))

ggplot(rout2, aes(series, phispanic, color = crime)) +
  geom_point(pch = 16, size = 3, alpha = .55) +
  scale_colour_manual(values = c("#aaaaaa","#5628a6", "#56a628"), guide = guide_legend(title = "")) +
  coord_flip() +
  scale_x_discrete(expand = c(.3, 1)) +
  scale_y_continuous(name = "Percentage of Hispanic Criminals",
	               limits = c(0, 100),
	               breaks = seq(0, 100, 10),
	               labels = paste0(seq(0, 100, 10), "%")) +
  xlab("") +
  cust_theme

ggsave("figs/all_criminals_by_race_hispanic.pdf", scale = .8)
