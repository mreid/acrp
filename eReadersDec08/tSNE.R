# Preprocessing of Lambton Library for tSNE.
# Data format for binary file `data.dat` is available at:
#  http://ticc.uvt.nl/~lvdrmaaten/Laurens_van_der_Maaten/t-SNE_files/User%20guide_2.pdf
#
# N				number of instances 		1 x int32
# D 			number of dimensions 		1 x int32
# no_dims 		target # of dimensions		1 x int32
# perplexity	parameter (default 30)		1 x double
# N_l 			percentage landmarks		1 x double
# X				data						(N x D) x double
# landmarks		if N_l specified			N_l x double
#
# First a PCA is performed that maps the data down to 30 dimensions (as per User Guide)
# Then the data is written to `data.dat` in the format specified and then the command 
# line tSNE tool must be called manually.

setwd("~/code/acrp/eReadersDec08")

library(RMySQL)
library(kernlab)

m <- dbDriver("MySQL")
con <- dbConnect(m, db="acrp", user="acrp", password="acrppass")

# Get all the popular loans
loans <- dbGetQuery(con, "select BorrowerID, WorkID from pop_loans")

# Get all the IDs of the popular books
workIDs <- dbGetQuery(con, 
"select 
	popular_works.WorkID 		as WorkID,
	tbllitwork.Title 			as Title,
	pop_loans.LibraryID 		as LibraryID,
	count(pop_loans.BorrowerID) as NumBorrowers
from 
	popular_works, pop_loans, tbllitwork
where 
	pop_loans.LibraryID = 2 and
	popular_works.WorkID = pop_loans.WorkID and
	popular_works.WorkID = tbllitwork.LitWorkID
group by
	popular_works.WorkID"
)

# Filter out rarely borrowed books
workIDs <- subset(workIDs, workIDs$NumBorrowers >= 20)

numWorks <- length(workIDs$WorkID)

# Get all the IDs of borrowers of popular books
borrowerIDs <- dbGetQuery(con, 
	"select distinct BorrowerID from pop_loans where LibraryID = 2"
)
numBorrowers <- length(borrowerIDs$BorrowerID)

getWorks <- function(borrowerID) { loans$WorkID[loans$BorrowerID == borrowerID] }
getBorrowers <- function(workID) { loans$BorrowerID[loans$WorkID == workID] }

# Compute docs table with works in rows 
docs <- matrix(nrow=numWorks, ncol=numBorrowers)
total <- length(borrowerIDs$BorrowerID)
bidx <- 0
for(b in borrowerIDs$BorrowerID) {
	bidx <- bidx + 1
	wIDs <- getWorks(b)
	docs[,bidx] <- as.numeric(workIDs$WorkID %in% wIDs)

	if(bidx %% 10 == 0) { cat("Completed ", bidx, " of ", total, "\n") }
}

# Write out records in docs in binary
#datfile <- file("raw.dat", "wb")
#writeBin(as.integer(nrow(docs)), datfile, size=4)
#writeBin(as.integer(ncol(docs)), datfile, size=4)
#for(i in 1:nrow(docs)) {
#	for(j in 1:ncol(docs)) {
#		writeBin(as.double(docs[i,j]), datfile, size=8)
#	}
#}
#close(datfile)

# Normalise the rows (books)
# Similarity represents proportion of borrowers in common
ndocs <- t(apply(docs, 1, function(row) { sqrt(row / sum(row)) }))

#kpc <- kpca(ndocs,kernel=vanilladot,kpar=list(),features=30);
#xys <- rotated(kpc)

# Write the binary file out in the tSNE format 
#datfile <- file("data.dat", "wb")
#writeBin(as.integer(nrow(xys)), datfile, size=4)
#writeBin(as.integer(ncol(xys)), datfile, size=4)
#writeBin(as.integer(2), datfile, size=4)
#writeBin(as.double(30), datfile, size=8)
#writeBin(as.double(1), datfile, size=8)
#for(i in 1:nrow(xys)) {
#	for(j in 1:ncol(xys)) {
#		writeBin(as.double(xys[i,j]), datfile, size=8)	
#	}
#}
#close(datfile)

target_dims <- 2
perplexity <- 5
perc_landmarks <- 1

datfile <- file("data.dat", "wb")
writeBin(as.integer(nrow(ndocs)), datfile, size=4)
writeBin(as.integer(ncol(ndocs)), datfile, size=4)
writeBin(as.integer(target_dims), datfile, size=4)
writeBin(as.double(perplexity), datfile, size=8)
writeBin(as.double(perc_landmarks), datfile, size=8)
for(i in 1:nrow(ndocs)) {
	for(j in 1:ncol(ndocs)) {
		writeBin(as.double(ndocs[i,j]), datfile, size=8)	
	}
}
close(datfile)

# Run the t-SNE command-line tool
system("./tSNE_maci", wait=TRUE) 

# Read the `result.dat` file back in
resultfile <- file("result.dat", "rb")
	n <- readBin(resultfile, integer(), 1)
	d <- readBin(resultfile, integer(), 1)

	mxys <- matrix(nrow=n, ncol=d)
	for(i in 1:n) {
		for(j in 1:d) {
			mxys[i,j] <- readBin(resultfile, double())
		}	
	}

	landmarks <- vector(length=n)
	for(i in 1:n) {
		landmarks[i] <- readBin(resultfile, integer(), 1) + 1
	}
close(resultfile)

# Reorder workIDs data frame and the docs matrix
workIDs <- workIDs[landmarks,]
docs <- docs[landmarks,]

# Compute the number of borrowers of each book
borrowCounts <- workIDs$NumBorrowers
borrowCounts <- borrowCounts / mean(borrowCounts)

# Plot the results. Borrow counts are used for circle radii.
plot(mxys, 
	main=paste("t-SNE of", numWorks, " Books\nLambton Miners' and Mechanics' Institute"),
	col=2,
	cex=borrowCounts,
	xlab=NA, ylab=NA, 
	xaxt="n", yaxt="n"
)

print("Writing out tSNE coordinates\n")
workIDs$x <- mxys[,1]
workIDs$y <- mxys[,2]
write.csv(workIDs, "../vis/data/lambton.csv", row.names=FALSE)

print("Computing neighbourhood matrix...\n")
neighbours <- docs %*% t(docs)

print("Writing out neighbourhood matrix...\n")
write.csv(
	cbind(workIDs$WorkID, neighbours), 
	"../vis/data/lambton-neighbours.csv", 
	row.names=FALSE
)
print("Done!\n")
