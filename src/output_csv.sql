
delimiter @

/* 
	Having this output interface layer allows us to control what fields
    make it into the exports, or apply final filtering logic. 
    
    That could be useful in the future, but it's a transparent layer for now.
    
    I don't generally like using * in production code but here it seems reasonable.
    For now, we're not making any commitments about column lists remaining constant
    over time.
*/

drop procedure if exists output_dim_date @
create procedure output_dim_date()
begin

	select	*
	from	dim_date
	;

end @

drop procedure if exists output_dim_society @
create procedure output_dim_society()
begin

	select	*
	from	dim_society
	;

end @

drop procedure if exists output_dim_society_combo @
create procedure output_dim_society_combo()
begin

	select	*
	from	dim_society_combo
	;

end @

drop procedure if exists output_dim_story @
create procedure output_dim_story()
begin

	select	*
	from	dim_story
	;

end @

drop procedure if exists output_dim_time @
create procedure output_dim_time()
begin

	select	*
	from	dim_time
	;

end @

drop procedure if exists output_dim_venue @
create procedure output_dim_venue()
begin

	select	*
	from	dim_venue
	;

end @

drop procedure if exists output_fct_performances @
create procedure output_fct_performances()
begin

	select	*
	from	fct_performances
	;

end @
