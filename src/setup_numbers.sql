
-- Credit https://gist.github.com/johngrimes/408559

--  small-numbers table
drop table 
	if exists 	numbers_small;
create table 	numbers_small(RowNo int not null primary key);
insert into 	numbers_small(RowNo)
	values 		(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)
;

-- main numbers table
drop table 
	if exists 	numbers;
create table 	numbers(RowNo bigint not null primary key)
;

insert into 	numbers(RowNo)
select 			  tenks.RowNo * 10000
				+ thousands.RowNo * 1000 
				+ hundreds.RowNo * 100 
				+ tens.RowNo * 10 
				+ ones.RowNo * 1
from 			numbers_small 	tenks
cross join 		numbers_small 	thousands
cross join 		numbers_small 	hundreds
cross join 		numbers_small 	tens
cross join 		numbers_small 	ones
limit 			1000000
;
