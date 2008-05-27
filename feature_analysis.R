# Analysis of Books as vectors of Borrowers
#
# TODO
# ----
# [_] Double check that when using `kpca` that rows correspond to instances.
 
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
	pop_loans.LibraryID != 0 and
	popular_works.WorkID = pop_loans.WorkID and
	popular_works.WorkID = tbllitwork.LitWorkID
group by
	popular_works.WorkID"
)
numWorks <- length(workIDs$WorkID)

# Get all the IDs of borrowers of popular books
borrowerIDs <- dbGetQuery(con, 
	"select distinct BorrowerID from pop_loans where LibraryID != 0"
)
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

	docs[,bidx] <- as.numeric(workIDs$WorkID %in% wIDs)
#	ws <- as.numeric(workIDs$WorkID %in% wIDs)
#	docs[,bidx] <- if(sum(ws) == 0) { 0 } else { sqrt(ws / sum(ws)) }
}

# No normalisation
# Similarity represents total number of borrowers in common
#ndocs <- docs

# Normalise the rows (books)
# Similarity represents proportion of borrowers in common
ndocs <- t(apply(docs, 1, function(row) { sqrt(row / sum(row)) }))

# Normalise the columns (borrowers)
#ndocs <- apply(docs, 2, function(col) { s = sum(col); if(s == 0) { col } else { sqrt(col / s) }})

# Compute the number of borrowers of each book
borrowCounts <- workIDs$NumBorrowers
borrowCounts <- borrowCounts / mean(borrowCounts)

neighbours <- docs %*% t(docs)

#nr <- dim(ndocs)[1]
#centerer <- diag(1, nr, nr) - 1/nr * (rep(1,nr) %*% t(rep(1,nr)))
#cdocs <- centerer %*% ndocs

#kpc <- kpca(ndocs,kernel=rbfdot,kpar=list(sigma=1),features=2);
kpc <- kpca(ndocs,kernel=vanilladot,kpar=list(),features=2);
xys <- rotated(kpc)
workIDs$x <- xys[,1]
workIDs$y <- xys[,2]

# write.csv(workIDs, "/tmp/test.csv", row.names=FALSE)

libcolour <- function(libid) {
	c("blue", "red", "", "green", "black", "", "", "orange", "gray")[libid %% 10]
}

plot(xys, 
	xlab="Borrower PC 1", ylab="Borrower PC 2", 
	main="Linear PCA of Books by Borrowers\nLambton Institute",
	col=sapply(workIDs$LibraryID, libcolour),
	cex=borrowCounts
)

# Put some titles on the plot, chosen at random
#s <- c("On Our Selection", "Master of Men", "Missionary, The", "Prince of Sinners, A", "Tempter's Power, The", "Our New Selection!", "Back at Our Selection", "Connie Burt", "Town and Bush") #sample(workIDs$Title, 10)
s <- c("On Our Selection", "Southerners, The", "Little Shepherd of Kingdom Come, The", "Master of Men", "Missionary, The", "Prince of Sinners, A", "Tempter's Power, The", "Our New Selection!") #sample(workIDs$Title, 10)
titles <- sapply(workIDs$Title, function(x) { if(x %in% s) { x } else {""} })
text(xys[,1], xys[,2], titles, cex=1, pos=1)

# Pick a book and draw lines to neighbours with at least threshold borrowers in
# common 
shownearby <- function(workID, threshold) {
	for(n in which(neighbours[workID,] > threshold)) {
		lines(c(workIDs$x[workID], workIDs$x[n]), c(workIDs$y[workID], workIDs$y[n]))
	}	
}

shownearby(154, 20)
