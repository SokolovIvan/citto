USE [AnalitDB]
GO
/****** Object:  StoredProcedure [edu].[p_KG_Children_visitng_by_age]    Script Date: 9/27/2020 10:51:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [edu].[p_KG_Children_visitng_by_age]


AS
BEGIN

declare @date date
set @date = getdate() - 1 
while @date < getdate() - 1 begin
	insert into edu.KG_Children_visitng_by_age (date, child_visitng, unit_id, age_cat_id,  age) 
	
	select @date, count (child_id) as child_visitng, unit_id,  g1.age_cat_id, age
from (
SELECT  child_id, max (g.group_id) as group_id,  DATEDIFF (day, c.birthdate, @date) / 365 as age
		FROM [AnalitDB].[edu].[KG_Placement_vers2] p
	join (
	SELECT [group_id]
      ,[date]
      ,[status]
	FROM [AnalitDB].[edu].[KG_GroupFields]
	where date = @date
	) g
	on p.group_id = g.group_id
	 join [AnalitDB].[edu].[KG_Children_vers2] c
	on c.id = child_id
	where g.status = 1 and p.date <= @date and (p.close_date is null or p.close_date > @date) and child_id not in (377408, 123381)
	group by child_id,  DATEDIFF (day, c.birthdate, @date) / 365 
	) as group_child
	join [AnalitDB].[edu].[KG_Groups] g1 on group_child.group_id = g1.id
	-- join [AnalitDB].[edu].[KG_Unit] u on g1.unit_id = u.id
	group by group_id, unit_id,  g1.age_cat_id, max_count, age

set @date = dateadd(day,1,@date)
end

END
