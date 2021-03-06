-- The following code is used to compute popular works and find how many
-- readers have read those works.

-- Loan information: books, copies of books, loans, borrowers and libraries.
-- drop table loans;
create table loans
	select
		work.LitWorkID			as WorkID,
		vol.ReadVolCopyID		as VolID,
		loan.ReadLoanIssueID 	as LoanID,
		loan.ReadBorrowerID		as BorrowerID,
		vol.ReadLibraryID		as LibraryID
	from 
		tbllitwork			as work
		inner join tblreadvolcopy as vol on work.LitWorkID = vol.LitWorkID
		inner join tblreadloanissue as loan on vol.ReadVolCopyID = loan.ReadVolCopyID
	;

-- Books and their total number of loans
-- drop table workcounts;
create table workcounts
	select
		WorkID, 
		count(LoanID)	as LoanCount
	from
		loans
	group by
		WorkID;

-- Books with at least 20 borrowers across all libraries.
-- drop table popular_works;
create table popular_works
	select WorkID from workcounts where LoanCount >= 20 order by LoanCount desc;

-- Loans for popular books.
-- drop table pop_loans;
create table pop_loans
	select distinct
		popular_works.WorkID as WorkID,
		loans.BorrowerID as BorrowerID,
		loans.LibraryID as LibraryID
	from 
		popular_works,
		loans
	where 
		loans.WorkID = popular_works.WorkID;
