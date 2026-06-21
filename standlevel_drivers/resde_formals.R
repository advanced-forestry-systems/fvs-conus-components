suppressMessages(library(resde))
cat("== sdemodel formals ==\n"); print(args(sdemodel))
cat("\n== sdefit formals ==\n"); print(args(sdefit))
cat("\n== sdemodel help examples ==\n")
db <- tools::Rd_db("resde")
for(nm in c("sdemodel.Rd","sdefit.Rd")){ if(!is.null(db[[nm]])){ tools::Rd2txt(db[[nm]], out=stdout()) } }
