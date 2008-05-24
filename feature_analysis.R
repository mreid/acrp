library(RMySQL)
library(kernlab)

m <- dbDriver("MySQL")
con <- dbConnect(m, db="acrp", user="acrp", password="acrppass") #, client.flag = CLIENT_MULTI_STATEMENTS)

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
	popular_works.WorkID = pop_loans.WorkID and
	popular_works.WorkID = tbllitwork.LitWorkID
group by 
	popular_works.WorkID"
)
numWorks <- length(workIDs$WorkID)

# Get all the IDs of borrowers of popular books
borrowerIDs <- dbGetQuery(con, "select distinct BorrowerID from pop_loans")
numBorrowers <- length(borrowerIDs$BorrowerID)

getWorks <- function(borrowerID) {
	loans$WorkID[loans$BorrowerID == borrowerID]
}

getBorrowers <- function(workID) {
	loans$BorrowerID[loans$WorkID == workID]
}

# Compute docs table with works in rows 
docs <- matrix(nrow=numWorks, ncol=numBorrowers)
total <- length(borrowerIDs$BorrowerID)
bidx <- 0
for(b in borrowerIDs$BorrowerID) {
	bidx <- bidx + 1
	wIDs <- getWorks(b)
	if(bidx %% 10 == 0) { cat(bidx, " of ", total, "\n") }
		
	numWorksRead <- length(wIDs)
	if(numWorksRead == 0) {
		cat("BorrowerID = ", b, " read ", numWorksRead, " book(s)\n")
	}

	ws <- as.numeric(workIDs$WorkID %in% wIDs)
	docs[,bidx] <- sqrt(ws / sum(ws))
}

# Compute the number of borrowers of each book
borrowCounts <- workInfo$NumBorrowers
borrowCounts <- borrowCounts / mean(borrowCounts)

kpc <- kpca(docs,kernel=vanilladot,kpar=list(),features=2)
xys <- rotated(kpc)
workIDs$x <- xys[,1]
workIDs$y <- xys[,2]

write.csv(workIDs, "/tmp/test.csv")

plot(xys, 
	xlab="Borrower PC 1", ylab="Borrower PC 2", 
	main="Linear PCA of Books by Borrowers\nMaitland Institute",
	col=sapply(workIDs$LibraryID, function(x) {x %% 14}),
	cex=borrowCounts
)

# Put some titles on the plot, chosen at random
s <- sample(workIDs$Title, 10)
titles <- sapply(workIDs$Title, function(x) { if(x %in% s) { x } else {""} })
text(xys[,1], xys[,2], titles, cex=0.7, pos=4)
