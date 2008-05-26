	
select count(*) from (select distinct BorrowerID from pop_loans where WorkID = 3564) as borrowers;

select count(*) from popular_works;

select distinct BorrowerID from pop_loans where WorkID = 1134294745;
select distinct BorrowerID from pop_loans where WorkID = 1112933613;

select distinct 
	t1.BorrowerID, t1.WorkID,
	t2.BorrowerID, t2.WorkID 
from 
	pop_loans as t1,
	pop_loans as t2
where 
	t1.WorkID = -898175613 and
	t2.WorkID = -1546612848 and
	t1.BorrowerID = t2.BorrowerID
;

select 
	LibraryID, 
	count(WorkID) as Count
from 
	pop_loans
group by 
	LibraryID;

select 
	popular_works.WorkID, 
	pop_loans.LibraryID 
from 
	popular_works 
	left join pop_loans 
	on popular_works.WorkID = pop_loans.WorkID 
group by popular_works.WorkID;

select 
	Count1, Count2, BothCount, 
	2 * BothCount / (Count1 + Count2) as Prob
from
	pop_pair_all
order by 
	Prob 

-- select 
-- 	Count1, Count2, BothCount,
-- 	work1.Title, work2.Title
-- from 
-- 	pop_pair_all as pair
-- 	inner join tbllitwork as work1 on work1.LitWorkID = pair.WorkID1
-- 	inner join tbllitwork as work2 on work2.LitWorkID = pair.WorkID2
-- where
-- 	Count1 >= 100 and Count2 >= 100
-- 	and BothCount < 5
-- ;