USE [AnalitDB]
GO
/****** Object:  StoredProcedure [edu].[p_KG_Unit_maxcount]    Script Date: 9/27/2020 10:56:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [edu].[p_KG_Unit_maxcount]


AS
BEGIN

declare @date date
set @date = getdate() - 1
while @date < getdate() - 1
 begin
	insert into [edu].[KG_Unit_max_count] (date, count_index, unit_count, unit_id) 
	
select @date as date, row_number() over(ORDER BY sum(max_count)) as count_index, sum(max_count) as unit_count,  unit_id from (
	select @date as date, count (group_child.child_id) as child_visitng, group_id, unit_id,  g1.age_cat_id, max_count

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
	group by child_id
	) as group_child
	join [AnalitDB].[edu].[KG_Groups] g1 on group_child.group_id = g1.id
	-- join [AnalitDB].[edu].[KG_Unit] u on g1.unit_id = u.id

	group by group_id, unit_id,  g1.age_cat_id, max_count
	) as m_by_unit
	group by unit_id
	order by sum(max_count)

set @date = dateadd(day,1,@date)
end

END
