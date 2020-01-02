
delimiter @

drop procedure if exists run_extract@
create procedure run_extract()
begin

	call extract_dimensions();
	call extract_facts();

end @

drop procedure if exists run_load_dims@
create procedure run_load_dims()
begin

	call load_dim_society();
	call load_dim_story();
	call load_dim_venue();
    
end @

drop procedure if exists run_load_fcts@
create procedure run_load_fcts()
begin

	call load_fct_performances();

end @

drop procedure if exists run_all@
create procedure run_all()
begin

	call run_extract();
    call run_load_dims();
    call run_load_fcts();

end @

delimiter ;

