ok <- requireNamespace("resde", quietly=TRUE)
cat("resde installed:", ok, "\n")
if(ok){ cat("exported fns:\n"); print(ls(getNamespace("resde"))) }
