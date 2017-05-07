library("Hmisc")
library("DescTools")

table <- read.table("PROC/ts.1D")
tsp <- as.character(table[1,1])

# load Time Series file as a matrix
ts <- as.matrix(read.table(tsp))

# Calculate fischer r correlations
cor <- rcorr(ts, type = "pearson")
rm(table, tsp, ts)

# Transform Fischer r to z
corz <- FisherZ(cor$r)

# Clean matrix


# Save matrix
