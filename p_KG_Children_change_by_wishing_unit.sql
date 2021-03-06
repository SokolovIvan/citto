USE [AnalitDB]
GO
/****** Object:  StoredProcedure [edu].[p_KG_Children_change_by_wishing_unit]    Script Date: 9/27/2020 10:44:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [edu].[p_KG_Children_change_by_wishing_unit]


AS
BEGIN



declare @date date
set @date = getdate() - 1
while @date <= getdate() - 1  begin
 insert into  edu.KG_Children_wishing_unit ([date], child_cnt, unit_id) 


select @date, count( lc.child_id), [unit_id] from (
select [owner_id], [unit_id]
from ( SELECT  [owner_id]
        ,[unit_id]
	  ,ROW_NUMBER() over (partition by [owner_id] order by [date] desc)  as id_1 
  FROM [AnalitDB].[edu].[KG_Declarations_Units_vers2] where ord = 1) tmp where tmp.id_1 = 1) du
 
  join
    (select [id], [child_id] from (
SELECT   [id]
      ,[child_id]
  ,ROW_NUMBER() over (partition by [child_id] order by [create_date] desc)  as id_1 
  FROM (
  select * from [AnalitDB].[edu].[KG_Declarations_vers2] where id in (select [owner_id] from (
SELECT  [owner_id]
      ,[date]
      ,[status_id]
	  ,ROW_NUMBER() over (partition by [owner_id] order by [date] desc)  as id_2 
  FROM [AnalitDB].[edu].[KG_Declarations_Status_vers2]
  where [date] <= @date
) tmp
where id_2 = 1 and [status_id] = 8
)  
  ) tmp4
  where  [create_date] <= @date
  ) tmp where id_1 = 1 ) d on d.id = du.[owner_id]

  join (
  SELECT  
      [child_id]
  FROM [AnalitDB].[edu].[KG_list_change] where [date] = @date 
  and child_id not in (select child_id from [AnalitDB].[edu].KG_list_change_group where [date] = @date)) lc on lc.child_id = d.child_id
  
 group by [unit_id]

set @date = dateadd(day,1,@date)
end

END







