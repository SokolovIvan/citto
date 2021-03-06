USE [AnalitDB]
GO
/****** Object:  StoredProcedure [edu].[p_KG_Quene_by_stat_fdm]    Script Date: 9/27/2020 10:56:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [edu].[p_KG_Quene_by_stat_fdm]


AS
BEGIN


declare @date date
set @date = getdate() - 1
while @date <= getdate() - 1   begin
	insert into edu.KG_quene_stat_fdm (date, base_date, [unit_id], child_cnt, pref_date_year, pref_date_month, age_status, q_status)
 

select  @date, base_date, [unit_id], child_cnt, pref_date_year, pref_date_month, age_status, q_status

  from 
 (
select  [date] as base_date, [unit_id], count([child_id]) as child_cnt, year (pref_date) as pref_date_year, month(pref_date) as pref_date_month,  [age]
,case when [age] < 3  then '0-3' else '3-8' end as age_status,
case when year (pref_date) < 2019 or (year (pref_date) = 2019 and month(pref_date) <= 8) then 'actual_q'
else'waiting_q' end as q_status



from [AnalitDB].[edu].[KG_Child_quene_by_age] qba
 left join (
  select owner_id, date_begin, pref_date, date_end
  FROM [AnalitDB].[edu].[KG_Declarations_PrefDates_vers3]) pd3
  on qba.owner_id = pd3.owner_id and date >= date_begin and (date_end is null or date_end >= date)
  
where [date] in (SELECT distinct [date]
  FROM [AnalitDB].[edu].[KG_Child_quene_by_age]
  where [date] = dateadd(day,1-day(@date),@date)) 
  group by [date], [unit_id], year (pref_date), month(pref_date), [age], case when [age] < 3  then '0-3' else '3-8' end, case when year (pref_date) < 2019 or (year (pref_date) = 2019 and month(pref_date) <= 8) then 'actual_q'
else'waiting_q' end

union all -- добавляем всё то же самое, только статус возраста указываем строго '0-8'

select  [date] as base_date, [unit_id], count([child_id]) as child_cnt, year (pref_date) as pref_date_year, month(pref_date) as pref_date_month,  [age]
,'Всего' as age_status,
case when year (pref_date) < 2019 or (year (pref_date) = 2019 and month(pref_date) <= 8) then 'actual_q'
else'waiting_q' end as q_status



from [AnalitDB].[edu].[KG_Child_quene_by_age] qba
 left join (
  select owner_id, date_begin, pref_date, date_end
  FROM [AnalitDB].[edu].[KG_Declarations_PrefDates_vers3]) pd3
  on qba.owner_id = pd3.owner_id and date >= date_begin and (date_end is null or date_end >= date)
  
where [date] in (SELECT distinct [date]
  FROM [AnalitDB].[edu].[KG_Child_quene_by_age]
  where [date] = dateadd(day,1-day(@date),@date)) 
  group by [date], [unit_id], year (pref_date), month(pref_date), [age], case when year (pref_date) < 2019 or (year (pref_date) = 2019 and month(pref_date) <= 8) then 'actual_q'
else'waiting_q' end

) main


set @date = dateadd(day,1,@date)
end

END
