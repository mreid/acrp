drop view loans;

create view loans as
select 	loan.ReadBorrowerID 	as ReaderID,
		loan.ReadVolCopyID 		as CopyID,
		work.LitWorkID			as WorkID,
		loan.LoanIssueDate		as LoanDate
from		tblreadloanissue 	as loan,
			tbllitwork		 	as work 
inner join	tblreadvolcopy			as vol
on			(loan.ReadVolCopyID = vol.ReadVolCopyID and
			vol.LitWorkID = work.LitWorkID);
