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