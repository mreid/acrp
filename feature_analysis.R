library(RMySQL)
library(kernlab)

m <- dbDriver("MySQL")
con <- dbConnect(m, db="acrp", user="acrp", password="acrppass", client.flag = CLIENT_MULTI_STATEMENTS)

# Get all the IDs of borrowers of popular books
rs <- dbSendQuery(con, "select distinct BorrowerID from pop_loans")
borrowerIDs <- fetch(rs)
dbClearResult(rs)

# Get all the IDs of the popular books
rs <- dbSendQuery(con, "select distinct WorkID from pop_loans")
workIDs <- fetch(rs)
dbClearResult(rs)

docs <- data.frame()
script <- c()
for(w in workIDs) {
	script <- append(script, getBorrowers(w))
}
print(paste(script, sep=";"))

getBorrowers <- function(workID) {
	paste(
		"select distinct BorrowerID from pop_loans", 
		"where WorkID =", workID
	)
}