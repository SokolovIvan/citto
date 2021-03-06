USE [AnalitDB]
GO
/****** Object:  StoredProcedure [edu].[p_KG_moved_pref_dates]    Script Date: 9/27/2020 10:54:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [edu].[p_KG_moved_pref_dates]


AS
BEGIN

declare @date date
set @date = getdate() - 1
while @date < getdate() - 1 begin
	insert into [edu].[KG_Pref_date_move] (date, child_cnt, pd_status, unit_id, age) 
	
	SELECT  @date
      ,count ([child_id]) as child_cnt
      ,movedate_status
      ,[unit_id]
	 ,[age]
  FROM [AnalitDB].[edu].[KG_Child_quene_by_age] qba
  join (
  select main1.owner_id, 
case when pref_date_mindate < pref_date_maxdate then 'date_move'
when pref_date_mindate > pref_date_maxdate then 'date_closer' end as movedate_status
  from (
select owner_id, pref_date as pref_date_mindate  from
(SELECT  [id]
      ,[owner_id]
      ,[date_begin]
      ,[date_end]
      ,[pref_date]
	  ,ROW_NUMBER() over (partition by [owner_id] order by [date_begin] asc)  as id_datebegin_min 
	  ,ROW_NUMBER() over (partition by [owner_id] order by [date_begin] desc)  as id_datebegin_max 
  FROM [AnalitDB].[edu].[KG_Declarations_PrefDates_vers3] 
  where [date_begin] <= @date) main
  where [date_begin] <= @date and [owner_id] in (
  (SELECT [owner_id] from (
  SELECT [owner_id]
  , ROW_NUMBER() over (partition by [owner_id] order by [date_begin] desc)  as id_datebegin_min 
  FROM [AnalitDB].[edu].[KG_Declarations_PrefDates_vers3]) main where id_datebegin_min > 1
  and [date_begin] <= @date)
  ) and id_datebegin_min = 1
) main1
join
(select owner_id, pref_date as pref_date_maxdate from
(SELECT  [id]
      ,[owner_id]
      ,[date_begin]
      ,[date_end]
      ,[pref_date]
	  ,ROW_NUMBER() over (partition by [owner_id] order by [date_begin] asc)  as id_datebegin_min 
	  ,ROW_NUMBER() over (partition by [owner_id] order by [date_begin] desc)  as id_datebegin_max 
  FROM [AnalitDB].[edu].[KG_Declarations_PrefDates_vers3] 
  where [date_begin] <= @date) main
  where [date_begin] <= @date and [owner_id] in (
  (SELECT [owner_id] from (
  SELECT [owner_id]
  , ROW_NUMBER() over (partition by [owner_id] order by [date_begin] desc)  as id_datebegin_min 
  FROM [AnalitDB].[edu].[KG_Declarations_PrefDates_vers3]) main where id_datebegin_min > 1
  and [date_begin] <= @date)
  ) and id_datebegin_max = 1
  ) main2
  on main1.owner_id = main2.owner_id
) main3 on main3.owner_id = qba.owner_id
where qba.date = @date

group by  [unit_id], movedate_status, [age]

set @date = dateadd(day,1,@date)
end

END
