/****** Script for SelectTopNRows command from SSMS  ******/
select owner_id1, [date], old_value from (

SELECT  pdc1.[owner_id] as owner_id1
      ,id
	--  ,tmp3.owner_id
	--  ,tmp4.owner_id
	  ,[date_change]
      ,[old_value]
      ,[new_value]
	  ,CAST([date_change] as date) as [date] -- дата изменения желаемой даты
--	  ,tmp4.date
	  ,row_number() over(partition BY pdc1.[owner_id]  ORDER BY [date_change] ) idd_1 -- порядковый номер изменения данных декларации asc
	  ,row_number() over(partition BY pdc1.[owner_id]  ORDER BY [date_change] desc) idd_2 -- порядковый номер изменения данных декларации desc 
	  ,tmp3.max_idd -- максимальный порядковый номер по этой декларации
	  ,row_number() over(partition BY pdc1.[owner_id], CAST([date_change] as date) ORDER BY [date_change] ) id_1 -- порядковый номер изменения данных декларации в течение одного дня asc
	  ,row_number() over(partition BY pdc1.[owner_id], CAST([date_change] as date) ORDER BY [date_change] desc) id_2 -- порядковый номер изменения данных декларации в течение одного дня desc
	  ,tmp4.max_id -- максимальное количество изменений сроков в течение одного дня 
	  ,create_date -- дата создания декларации

  FROM [AnalitDB].[edu].[KG_Declarations_PrefDates_changedate1] pdc1
  join [AnalitDB].[edu].[KG_Declarations_vers2] dv2
  on pdc1.owner_id = dv2.id
  join (
  select [owner_id], max (idd_1) max_idd from (
SELECT  [owner_id]
	  ,row_number() over(partition BY [owner_id]  ORDER BY [date_change] ) idd_1
  FROM [AnalitDB].[edu].[KG_Declarations_PrefDates_changedate1] pdc1
 ) tmp1
  group by [owner_id]
  ) tmp3 on tmp3.[owner_id] = pdc1.owner_id
  join (
    select [owner_id], [date], max (id_1) max_id from (
SELECT  [owner_id]
,CAST([date_change] as date) as [date]
	  ,row_number() over(partition BY [owner_id], CAST([date_change] as date) ORDER BY [date_change] ) id_1
  FROM [AnalitDB].[edu].[KG_Declarations_PrefDates_changedate1] pdc1
 ) tmp1
  group by [owner_id], [date]
) tmp4 on tmp4.owner_id = pdc1.owner_id and tmp4.date = CAST([date_change] as date)
  where tmp4.max_id > 1 
 -- order by pdc1.[owner_id], [date_change]
  ) main
  where id_1 = 1