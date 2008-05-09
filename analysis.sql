select count(*) from (select distinct BorrowerID from pop_loans) as borrowers; 

select count(*) from (select distinct BorrowerID from pop_loans where WorkID = 3564) as borrowers;

select distinct BorrowerID from pop_loans where WorkID = 1134294745;
select distinct BorrowerID from pop_loans where WorkID = 1112933613;

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