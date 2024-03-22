library(argparse)
library(tidyverse)
library(data.table)

parser <- ArgumentParser()

parser$add_argument("-in","--indir", help="Where BCs are stored")
parser$add_argument("-stats", "--statsout", help="Where to save BC stats")
parser$add_argument("-summ", "--summout", help="Where to save summary BC table")

args <- parser$parse_args()

###
# Prepare barcode stats

# convert the input directory argument to a character vector
files <- strsplit(args$inlist, ",")[[1]]

# initialize values
topthresh <- midthresh <- lowthresh <- maxbc <- topfrac <- midfrac <- lowfrac <- numeric(length(files))

length(files)

for(i in seq_along(files)) {
  t <- fread(files[i], fill = TRUE)
  ts <- t %>% arrange(desc(V2)) %>% mutate(V2 = as.numeric(V2)) %>% filter(!is.na(V2))
  cfvs <- cumsum(ts$V2)/sum(ts$V2)
  topthresh[i] <- min(which(cfvs >= 0.95))
  midthresh[i] <- min(which(cfvs >= 0.9))
  lowthresh[i] <- min(which(cfvs >= 0.8))
  maxbc[i] <- length(cfvs)
  topfrac[i] <- topthresh[i]/maxbc[i]
  midfrac[i] <- midthresh[i]/maxbc[i]
  lowfrac[i] <- lowthresh[i]/maxbc[i]
}

# gather stats into summary table
results <- data.frame(files, maxbc, lowthresh, midthresh, topthresh, lowfrac, midfrac, topfrac)
results <- results %>%
  mutate(name = str_extract(files, "/(.+?).bc_clust.txt"))

# write out summary table
write.table(results, file.path(args$statsout), row.names = FALSE, quote = FALSE, sep = "\t")

# prepare barcode counts

# define a function to merge and fill missing values with 0
merge_and_fill <- function(x, y, by_var) {
  full_join(x, y, by = by_var)
}

# read in tables
table_list <- lapply(files, fread)
table_list <- lapply(table_list, function(x) x[,c(1:2)])
table_list <- lapply(table_list, function(x) x  %>% rename("barcode" = "V1", "counts" = "V2"))

# Merge the tables
result <- Reduce(function(x, y) merge_and_fill(x, y, "barcode"), table_list)

# select columns of interest
colnames(result)[2:length(colnames(result))] <- paste0("sample", seq(1,length(colnames(result))-1))
result[is.na(result)] <- 0

# Print or save the result
write.table(result, file.path(args$summout), row.names = FALSE, quote = FALSE, sep = "\t")
