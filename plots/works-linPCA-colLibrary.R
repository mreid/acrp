library(RMySQL)
library(kernlab)

m <- dbDriver("MySQL")
con <- dbConnect(m, db="acrp", user="acrp", password="acrppass") #, client.flag = CLIENT_MULTI_STATEMENTS)

# Get all the IDs of the popular books
workIDs <- dbGetQuery(con, 
 	"select popular_works.WorkID, pop_loans.LibraryID from popular_works, pop_loans where popular_works.WorkID = pop_loans.WorkID group by popular_works.WorkID"
)

# Get all the IDs of borrowers of popular books
borrowerIDs <- dbGetQuery(con, "select distinct BorrowerID from pop_loans")

getWorks <- function(borrowerID) {
	query <- paste(
		"select distinct WorkID from pop_loans", 
		"where BorrowerID =", borrowerID
	)
	dbGetQuery(con, query)
}

getBorrowers <- function(workID) {
	query <- paste(
		"select distinct BorrowerID from pop_loans", 
		"where WorkID =", borrowerID
	)
	dbGetQuery(con, query)
}

# Compute docs table with works in rows and 
docs <- data.frame(row.names = workIDs[[1]])
mean <- rep(0, length(workIDs[[1]]))
total <- length(borrowerIDs[[1]])
bidx <- 0
for(b in borrowerIDs[[1]]) {
	bidx <- bidx + 1
	if(!is.na(b)) {
		wIDs <- getWorks(b)
		if(bidx %% 10 == 0) {
			print(sprintf("%d of %d", bidx, total))
		}
#		print(sprintf("BorrowerID = %d: %d", b, length(wIDs[[1]])))

		ws <- rep(0, length(workIDs[[1]]))
		num <- 0
		for(w in wIDs[[1]]) {
			idx <- which(workIDs == w)
			if(idx != 0) {
				ws[[idx[[1]]]] <- 1
				num <- num + 1
			}
		}
		docs[[as.character(b)]] <- ws #/ num
#		mean <- mean + ws / num
	}
}

# Normalisation...
#mean <- mean / length(borrowerIDs[[1]])
#for(idx in 1:(length(docs[[1]]))) {
#	docs[[idx]] <- docs[[idx]] - mean
#}

kpc <- kpca(~., data=docs,kernel=vanilladot,kpar=list(),features=2)
plot(rotated(kpc), 
	xlab="Borrower PC 1", ylab="Borrower PC 2", 
	main="Linear PCA of Books by Borrowers\nColoured by Library",
	col=sapply(workIDs[[2]], function(x) {x %% 14})
)
