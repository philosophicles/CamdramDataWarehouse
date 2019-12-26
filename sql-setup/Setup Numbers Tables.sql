
drop procedure if exists camdram_dw.setup_numbers;
delimiter @
create procedure camdram_dw.setup_numbers()
begin

	-- Credit https://gist.github.com/johngrimes/408559

	--  small-numbers table
	drop table 
		if exists 	camdram_dw.numbers_small;
	create table 	camdram_dw.numbers_small(RowNo int not null primary key);
	insert into 	camdram_dw.numbers_small(RowNo)
		values 		(0),(1),(2),(3),(4),(5),(6),(7),(8),(9)
	;

	-- main numbers table
	drop table 
		if exists 	camdram_dw.numbers;
	create table 	camdram_dw.numbers(RowNo bigint not null primary key)
    ;
	
    insert into 	camdram_dw.numbers(RowNo)
	select 			  tenks.RowNo * 10000
					+ thousands.RowNo * 1000 
					+ hundreds.RowNo * 100 
                    + tens.RowNo * 10 
                    + ones.RowNo * 1
	from 			camdram_dw.numbers_small 	tenks
    cross join 		camdram_dw.numbers_small 	thousands
    cross join 		camdram_dw.numbers_small 	hundreds
    cross join 		camdram_dw.numbers_small 	tens
	cross join 		camdram_dw.numbers_small 	ones
	limit 			1000000
    ;

end @
delimiter ;

call camdram_dw.setup_numbers();