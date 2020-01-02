
drop procedure if exists camdram_dw.run_dim_story;
delimiter @
create procedure camdram_dw.run_dim_story()
begin
    
    /*
    This dimension is a bit different to society and venue,
    because Camdram itself doesn't manage this as an entity - no id.
    
    We don't want to do LOADS of data cleansing here, because it would
    become too hard to tie what's seen in this dataset back to actual Camdram
    data; "stories" are such a fundamental way of searching the site. 
    If we want to tidy the data much, then in general, we should make the 
    changes in the live site and let the data warehouse update to reflect it.
    
    However, we do need to do a little cleansing to make the dataset practical; 
    minor differences of empty strings, nulls, etc, don't have much bearing in the 
    live site. Cleansing here should be limited in spirit to those "backend details".
    
    To make that possible and allow looking up of the surrogate keys for the fact table,
    without having to repeat this cleansing logic somewhere else, 
    we need to make the data cleansing via in-place updates to parallel fields.
    */
    
    /*** Data cleansing ***/
		-- This can have multiple updates per field if needed!
    
	-- StoryName
	-- No cleansing for now - this cannot be blank
    update 		camdram_dw.extract_dim_story		ST
    set			ST.StoryName = ST.StoryNameRaw
    where 		ST.StoryName is null
    ;
    
    -- StoryAuthor
    -- Clean null and blank values to a consistent default
    update 		camdram_dw.extract_dim_story		ST
    set			ST.StoryAuthor = coalesce(nullif(trim(ST.StoryAuthorRaw),''), 'Unknown Author')
    where 		ST.StoryAuthor is null
    ;
    
    -- StoryType
    -- There's a bunch of 0 values hanging around; the front-end shows
	-- these as 'drama' so we shall as well. 
    update 		camdram_dw.extract_dim_story		ST
    set			ST.StoryType = case when ST.StoryTypeRaw = '0' then 'drama' else ST.StoryTypeRaw end
    where 		ST.StoryType is null
    ;
    
    /*** Populate dimension ***/
    truncate table camdram_dw.dim_story;
    
    insert into camdram_dw.dim_story
    (
		StoryName
        ,StoryAuthor
        ,StoryType
    )
    select 	
				distinct	-- Probably unnecessary but doesn't hurt
				StoryName
				,StoryAuthor
				,StoryType
    from 		camdram_dw.extract_dim_story
    order by 	StoryAuthor
				,StoryName
    ;
    
    /*** Retroactively apply generated StoryKey ***/
		-- This is for performance of the eventual Fact table processing, 
        -- since we appear to be limited to nested loops in mysql/mariadb :-(.
        -- This is still quite slow!
    update 		camdram_dw.extract_dim_story			E
	inner join 	camdram_dw.dim_story					S	on E.StoryName = S.StoryName
															and E.StoryAuthor = S.StoryAuthor
                                                            and E.StoryType = S.StoryType
    set 		E.StoryKey = S.StoryKey
    ;

end @
delimiter ;

call camdram_dw.run_dim_story();