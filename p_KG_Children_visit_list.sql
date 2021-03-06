USE [AnalitDB]
GO
/****** Object:  StoredProcedure [edu].[p_KG_Children_visit_list]    Script Date: 9/27/2020 10:49:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [edu].[p_KG_Children_visit_list]
-- изначально данные были только с 31.12.2019. Делаю загрузку с 01.01.2019 по 30.12.2019. В отчёт qlik должны попадать данные только с 31.12.2019 и старше.

AS
BEGIN

declare @date date
set @date = getdate() - 1

while @date <= getdate() - 1 begin
insert into edu.[KG_list_visit] (date, [child_id], [group_id])



select @date, child_id, group_id
from (
-- отбираются дети из таблицы плейсмент, с максимальным номером группы, и только действующие группы. выборка group_child
SELECT  p.child_id, max (g.group_id) as group_id
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
	and p.child_id in (select id from [AnalitDB].[edu].[KG_Children_vers2] union select id from [AnalitDB].[edu].[KG_Children])
	and child_id not in (377408, 123381)
	group by child_id
	) as group_child
	

set @date = dateadd(day,1,@date)
end

end