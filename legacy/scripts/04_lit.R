"
Include Lit. Review Table

"

# Set working dir.
setwd(githubdir)
setwd("face_of_crime/")

# Load libs
library(xtable)

# Read in data
lit <- read.csv("data/lit.csv")

names(lit) <- c("Region Covered", "Time frame", "Media", "Key Relevant Findings", "Citation")

print(
	  xtable(lit, 
	  	caption = "Racial Distribution of Perpetrators and Victims on Various Television Shows", 
	  	align = c("p{0.04\\textwidth}", "p{0.1\\textwidth}", "p{0.1\\textwidth}", "p{0.1\\textwidth}", "p{0.55\\textwidth}", "p{0.12\\textwidth}"), label = "tab:lit"), 
		include.rownames = FALSE,
	    include.colnames = TRUE,
	    size = "\\tiny", 
	    type = "latex", sanitize.text.function = function(x){x},
	    caption.placement = "top",
	    table.placement = "!htb",
	    file = "tabs/lit.tex")
