-- Final presentation interface for publicly shared data

drop view if exists camdram_performances;
create view camdram_performances as

	select 		FCT.PerformanceDateTimeStamp
				,FCT.ShowId
				,FCT.MinTicketPrice_GBP
				,FCT.MaxTicketPrice_GBP
				,FCT.CountOfCast
				,FCT.CountOfCrew
				,FCT.CountOfBand
				,ST.*
				,SCC.SocietyDisplaySortOrder
				,SOC.*
				,VN.*
				,DT.*
				,TM.*

	from 		fct_performances		FCT
	inner join 	dim_date				DT	on FCT.PerformanceDateKey = DT.DateKey
	inner join	dim_time				TM	on FCT.PerformanceTimeKey = TM.TimeKey
	inner join 	dim_society_combo		SCC	on FCT.SocietyComboKey = SCC.SocietyComboKey
	inner join 	dim_society				SOC	on SCC.SocietyKey = SOC.SocietyKey
	inner join 	dim_venue				VN	on FCT.VenueKey = VN.VenueKey
	inner join 	dim_story				ST	on FCT.StoryKey = ST.StoryKey

	where		DT.AcademicYearNum >= 2004
;
