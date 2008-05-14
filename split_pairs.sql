-- The following code is used to compute pairs of popular works and find how many
-- readers have read both works.
--
-- For efficiency, tables are created along the way to store and view partial 
-- results.

drop table loans;
create table loans
	select
		work.LitWorkID			as WorkID,
		vol.ReadVolCopyID		as VolID,
		loan.ReadLoanIssueID 	as LoanID,
		loan.ReadBorrowerID		as BorrowerID
	from 
		tbllitwork			as work
		inner join tblreadvolcopy as vol on work.LitWorkID = vol.LitWorkID
		inner join tblreadloanissue as loan on vol.ReadVolCopyID = loan.ReadVolCopyID;

drop table workcounts;
create table workcounts
	select
		WorkID, 
		count(LoanID)	as LoanCount
	from
		loans
	group by
		WorkID;
		
drop table popular_works;
create table popular_works
	select WorkID from workcounts where LoanCount >= 20 order by LoanCount desc;

drop table pop_loans;
create table pop_loans
	select distinct
		popular_works.WorkID as WorkID,
		loans.BorrowerID as BorrowerID
	from 
		popular_works,
		loans
	where 
		loans.WorkID = popular_works.WorkID;

-- drop table pop_borrower_pairs;
-- create table pop_borrower_pairs as
-- 	select distinct
-- 		pop1.BorrowerID as BorrowerID,
-- 		pop1.WorkID as WorkID1,
-- 		pop2.WorkID as WorkID2
-- 	from
-- 		pop_loans as pop1,
-- 		pop_loans as pop2
-- 	where
-- 		pop1.BorrowerID = pop2.BorrowerID and
-- 		pop1.WorkID < pop2.WorkID
-- 	;
-- 
-- drop table pop_pair_counts;
-- create table pop_pair_counts as
-- 	select
-- 		pop.WorkID1 as WorkID1,
-- 		pop.WorkID2 as WorkID2,
-- 		count(pop.BorrowerID) as BothCount
-- 	from
-- 		pop_borrower_pairs as pop
-- 	group by
-- 		WorkID1, WorkID2
-- 	;
-- 
-- drop table pop_pair_all;
-- create table pop_pair_all as
-- 	select
-- 		pop.WorkID1 as WorkID1,
-- 		pop.WorkID2 as WorkID2,
-- 		counts1.LoanCount as Count1,
-- 		counts2.LoanCount as Count2,
-- 		pop.BothCount as BothCount
-- 	from
-- 		pop_pair_counts as pop
-- 		inner join workcounts as counts1 on pop.WorkID1 = counts1.WorkID
-- 		inner join workcounts as counts2 on pop.WorkID2 = counts2.WorkID
-- 	;
