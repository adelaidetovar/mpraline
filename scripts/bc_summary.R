library(argparse)
library(tidyverse)
library(data.table)

parser <- ArgumentParser()

parser$add_argument("-in","--indir", help="Where BCs are stored")
parser$add_argument("-out", "--outdir", help="Where to save summary table")

args <- parser$parse_args()

# prepare BC stats

# make list of all BC count files
files <- list.files(path=args$indir, pattern="*.txt", full.names=TRUE, recursive=FALSE)
topthresh <- midthresh <- lowthresh <- maxbc <- topfrac <- midfrac <- lowfrac <- numeric(length(files))

length(files)

for(i in seq_along(files)) {
  t <- fread(files[[i]], fill = T)
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

results <- data.frame(files, maxbc, lowthresh, midthresh, topthresh, lowfrac, midfrac, topfrac)
results <- results %>%
  mutate(name = str_extract(files, "/(.+?).bc_clust.txt"))

write.table(results, paste0(args$outdir, "bc_stats.txt"), row.names = F, quote = F, sep = "\t")


# prepare barcode counts

# define a function to merge and fill missing values with 0
merge_and_fill <- function(x, y, by_var, suffix) {
  left_join(x, y, by = by_var) %>%
    mutate(across(ends_with(suffix), ~coalesce(., 0)))
}

# read in tables
table_list <- lapply(files, fread)

# Merge the tables
result <- Reduce(function(x, y) merge_and_fill(x, y, "barcodes", paste0("_sample", match(y, table_list))), table_list)

# select columns of interest
result <- select(result, barcodes, starts_with("counts"))

# Print or save the result
write.table(result, paste0(args$outdir, "summary_table.txt"), row.names = F, quote = F, sep = "\t")
