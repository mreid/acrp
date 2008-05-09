library(RMySQL)
library(kernlab)

m <- dbDriver("MySQL")
con <- dbConnect(m, db="acrp", user="acrp", password="acrppass", client.flag = CLIENT_MULTI_STATEMENTS)

# Get all the IDs of borrowers of popular books
borrowerIDs <- dbGetQuery(con, "select distinct BorrowerID from pop_loans")

# Get all the IDs of the popular books
workIDs <- dbGetQuery(con, "select distinct WorkID from pop_loans")

getBorrowers <- function(borrowerID) {
	query <- paste(
		"select distinct WorkID from pop_loans", 
		"where BorrowerID =", borrowerID
	)
	bs <- dbGetQuery(con, query)
}

docs <- data.frame(row.names = workIDs[[1]])
for(b in borrowerIDs[[1]]) {
	wIDs <- getBorrowers(b)
	print(sprintf("BorrowerID = %d: %d", b, length(wIDs[[1]])))

	ws <- rep(0, length(workIDs[[1]]))
	for(w in wIDs[[1]]) {
		
	}
	docs <- rbind(docs,data.frame(bs))
	docs[[as.character(b)]] 
}
