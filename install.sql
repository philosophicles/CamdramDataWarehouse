
-- Create schema/database to hold the data warehouse
-- MODIFY THESE LINES if you want to use a different schema/database name
drop schema if exists camdram_dw;
create schema camdram_dw
	default character set utf8mb4 collate utf8mb4_0900_as_cs
;
use camdram_dw;

-- END part to modify; everything below will use the stated schema.

-- Create basic objects, and in some cases pre-populate them
source src/setup_numbers.sql
source src/setup_extract_tables.sql
source src/setup_extract_views.sql
source src/setup_final_tables.sql
source src/setup_time.sql
source src/setup_date.sql

-- Create stored procedures (but not execute them)
source src/extract_dimensions.sql
source src/extract_facts.sql
source src/load_dim_society.sql
source src/load_dim_story.sql
source src/load_dim_venue.sql
source src/load_fct_performances.sql
source src/runners.sql
