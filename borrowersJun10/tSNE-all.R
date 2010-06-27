# Preprocessing of All Libraries for tSNE.
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

setwd("~/code/acrp/borrowersJun10")

config <- data.frame(
	datadir = "../vis/data/borrowers2010",
	tSNE = "./tSNE_maci",
	target_dims = 2,
	perplexity = 10,
	perc_landmarks = 1
)

library(RMySQL)

m <- dbDriver("MySQL")
con <- dbConnect(m, db="acrp", user="acrp", password="acrppass")

# Get all the regular loans
loans <- dbGetQuery(con, "select BorrowerID, WorkID from regular_loans")

# Get all the IDs of regular borrowers (At least 5 loans)
borrowerIDs <- dbGetQuery(con, 
"select
	regular_borrowers.BorrowerID 		as BorrowerID,
	count(regular_loans.BorrowerID)		as NumWorks,
	tblreadborrower.Gender				as Gender,
	tblreadborrower.FirstName			as FirstName,
	tblreadborrower.Surname				as Surname,
	tblreadborrower.ReadLibraryID		as LibraryID
#	tblreadoccupation.Name				as Occupation
from 
	regular_borrowers, regular_loans, tblreadborrower#, tblreadoccupation
where
	regular_borrowers.BorrowerID = regular_loans.BorrowerID and
	regular_borrowers.BorrowerID = tblreadborrower.ReadBorrowerID
#	tblreadborrower.ReadOccupationID = tblreadoccupation.ReadOccupationID  
group by 
	regular_borrowers.BorrowerID"
)

numBorrowers <- length(borrowerIDs$BorrowerID)
cat("Processing a total of ", numBorrowers, " borrowers.\n")

# Get all the IDs of the books borrowed by regular borrowers
workIDs <- dbGetQuery(con, 
	"select distinct WorkID from regular_loans"
)
numWorks <- length(workIDs$WorkID)
cat("Processing a total of ", numWorks, " works.\n")

getWorks <- function(borrowerID) { loans$WorkID[loans$BorrowerID == borrowerID] }
getBorrowers <- function(workID) { loans$BorrowerID[loans$WorkID == workID] }

# Compute docs table with works in rows 
docs <- matrix(ncol=numWorks, nrow=numBorrowers)
total <- length(workIDs$WorkID)
widx <- 0
for(w in workIDs$WorkID) {
	widx <- widx + 1
	bIDs <- getBorrowers(w)
	docs[,widx] <- as.numeric(borrowerIDs$BorrowerID %in% bIDs)

	if(widx %% 10 == 0) { cat("Completed ", widx, " of ", total, "\n") }
}

# Normalise the rows (books)
# Similarity represents proportion of borrowers in common
# ndocs <- t(apply(docs, 1, function(row) { sqrt(row / sum(row)) }))
ndocs <- docs

datfile <- file("data.dat", "wb")
writeBin(as.integer(nrow(ndocs)), datfile, size=4)
writeBin(as.integer(ncol(ndocs)), datfile, size=4)
writeBin(as.integer(config$target_dims), datfile, size=4)
writeBin(as.double(config$perplexity), datfile, size=8)
writeBin(as.double(config$perc_landmarks), datfile, size=8)
for(i in 1:nrow(ndocs)) {
	for(j in 1:ncol(ndocs)) {
		writeBin(as.double(ndocs[i,j]), datfile, size=8)	
	}
}
close(datfile)

# Run the t-SNE command-line tool
system(paste(config$tSNE), wait=TRUE) 

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
# workIDs <- workIDs[landmarks,]
borrowerIDs <- borrowerIDs[landmarks,]
docs <- docs[landmarks,]

# Compute the number of books per borrower
borrowCounts <- borrowerIDs$NumWorks
borrowCounts <- borrowCounts / mean(borrowCounts)

# Plot the results. Borrow counts are used for circle radii.
plot(mxys, 
	main=paste("t-SNE of", numBorrowers, " Borrowers\nAll Libraries"),
	col=borrowerIDs$Gender + 2,
#	col=borrowerIDs$LibraryID %% 5 + 1,
	cex=sqrt(borrowCounts),
	xlim=c(-50,50), ylim=c(-50,50),
	xlab=NA, ylab=NA
#	xaxt="n", yaxt="n"
)

print("Writing out configuration")
write.csv(config, 
	paste(config$datadir, "/config.csv", sep=''),
	row.names=FALSE
)

print("Writing out tSNE coordinates\n")
borrowerIDs$x <- mxys[,1]
borrowerIDs$y <- mxys[,2]
write.csv(borrowerIDs, 
	paste(config$datadir, "/coords.csv", sep=''), 
	row.names=FALSE
)

print("Computing neighbourhood matrix...\n")
neighbours <- docs %*% t(docs)

print("Writing out neighbourhood matrix...\n")
write.csv(
	cbind(borrowerIDs$BorrowerID, neighbours), 
	paste(config$datadir, "/neighbours.csv", sep=''), 
	row.names=FALSE
)

print("Writing out the libraries table...\n")
write.csv(libraries, 
	paste(config$datadir, "/libraries.csv", sep=''), 
	row.names=FALSE
)

print("Writing out work/libraries table...\n")
write.csv(libworks, 
	paste(config$datadir, "/worklibs.csv", sep=''), 
	row.names=FALSE
)

print("Done!\n")


# Utility functions
similarity <- function(b1, b2) {
	ws1 <- getWorks(b1);
	ws2 <- getWorks(b2);
	as.numeric(workIDs$WorkID %in% ws1) %*% as.numeric(workIDs$WorkID %in% ws2)
}
