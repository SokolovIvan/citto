USE [AnalitDB]
GO
/****** Object:  StoredProcedure [edu].[p_KG_Children_change_by_age]    Script Date: 9/27/2020 10:42:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [edu].[p_KG_Children_change_by_age]


AS
BEGIN

 declare @date date
 set @date = getdate() - 1
while @date < getdate() - 1 begin
 insert into edu.KG_Child_change_by_age (date, child_cnt, unit_id, age) 



 select @date, count (distinct child_id) as child_cnt, unit_id,  datediff(year,(0),datediff(day,[birthdate],@date))

 from (

 SELECT child_id, max (g.group_id) as group_id
  FROM [AnalitDB].[edu].[KG_Placement_vers2] p
  join (
  SELECT [group_id]
      ,[date]
      ,[status]
  FROM [AnalitDB].[edu].[KG_GroupFields]
  where date = @date
  ) g
  on p.group_id = g.group_id
where g.status = 1 and p.date <= @date and (p.close_date is null or p.close_date > @date) 
-- Конец отбора детей, которые ходят в ДС в настоящее время.
-- Ниже отбираем детей из списка очередников
and child_id in (
select child_id 
FROM [AnalitDB].[edu].[KG_list_change] where [date] = @date)


-- ограничиваем выборку детьми, которые подали заявление о переводе в другой ДС, и где есть такие данные

group by child_id ) as group_child

join [AnalitDB].[edu].[KG_Groups] g1 on group_child.group_id = g1.id

	join [AnalitDB].[edu].[KG_Children_vers2] c on c.id = group_child.child_id
where child_id not in (select child_id from [AnalitDB].[edu].KG_list_change_group where [date] = @date)
	group by unit_id,  datediff(year,(0),datediff(day,[birthdate],@date))


set @date = dateadd(day,1,@date)
end

END