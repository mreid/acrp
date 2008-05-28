# Analysis of Books as vectors of Borrowers for the Lambton Library
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

# Normalise the rows (books)
# Similarity represents proportion of borrowers in common
ndocs <- t(apply(docs, 1, function(row) { sqrt(row / sum(row)) }))

# Compute the number of borrowers of each book
borrowCounts <- workIDs$NumBorrowers
borrowCounts <- borrowCounts / mean(borrowCounts)

kpc <- kpca(ndocs,kernel=rbfdot,kpar=list(sigma=1.2),features=2);
xys <- rotated(kpc)
workIDs$x <- xys[,1]
workIDs$y <- xys[,2]

print("Writing out PCA coordinates\n")
write.csv(workIDs, "../vis/data/lambton_rbf.csv", row.names=FALSE)

plot(xys, 
	main=paste("Linear PCA of", numWorks, " Books\nLambton Miners' and Mechanics' Institute"),
	col=2,
	cex=borrowCounts,
	xlab=NA, ylab=NA, 
	xaxt="n", yaxt="n"
)

print("Computing neighbourhood matrix...\n")
neighbours <- docs %*% t(docs)

print("Writing out neighbourhood matrix...\n")
write.csv(
	cbind(workIDs$WorkID, neighbours), 
	"../vis/data/lambton-neighbours.csv", 
	row.names=FALSE
)
print("Done!\n")
