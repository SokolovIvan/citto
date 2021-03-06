USE [AnalitDB]
GO
/****** Object:  StoredProcedure [edu].[p_KG_list_quene]    Script Date: 9/27/2020 10:54:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [edu].[p_KG_list_quene]


AS
BEGIN

declare @date date
set @date = getdate() - 1 

insert into  [AnalitDB].[edu].[KG_list_quene]
select @date, child_id from
(Select distinct  child_id
  FROM (select id, child_id FROM [AnalitDB].[edu].[KG_Declarations_vers2] where id in (
SELECT  [owner_id] FROM [AnalitDB].[edu].[KG_Declarations_Units_vers2] where ord = 1)
  ) Declarations_clear
  
  join (
  -- К списку заявлением присоединяем заявления с последними статусами  (1, 3, 7)
select d.owner_id, d.status_id, d.date from [AnalitDB].[edu].[KG_Declarations_Status] d join 
-- показываем самую позднюю дату и для каждого заявления, при условии что дата не позднее установленной
(
select max (date) as max_date, [owner_id] 
from (SELECT [owner_id]
      ,[status_id]
      ,[date]
  FROM [AnalitDB].[edu].[KG_Declarations_Status]
  where date <= @date) del_by_date
group by [owner_id]) as max_date_declaration
on max_date_declaration.max_date = date and [max_date_declaration].[owner_id] = d.[owner_id]
where status_id  in (1, 3, 7, 13)) as tmp
on Declarations_clear.id = tmp.owner_id
-- из списка исключаем детей, которые дублируют детей, имевшихся в таблице  Placement
/* В БД имеет место ситуация, когда на одного ребёнка заводятся несколько id записей. При этом, соответственно, эти несколько
записей должны быть подсчитаны один раз, и правильно.
Для этого все дети по которым есть заявления, сравниваются друг с другом, по показателям id, имя, дата рождения, и 
реквизиты свидетельства о рождении. Если совпадают имя, дата рождения и свидетельство о рождении, считается, что это
один ребёнок, на которого заведено несколько id. Сравнивать только по свидетельствам о рождении нельзя, поскольку есть
существенное количество свидетельств о рождении с одним номером, но по разным детям.
Если ребёнок есть в таблице  [KG_Placement], значит это реальный ребёнок. "Дубли" это ребёнка не должны учитываться для
расчёта показателей.
*/
where child_id not in (
SELECT dbl.child_id as sec_child_id
  FROM [AnalitDB].[edu].[KG_Declarations_vers2] d
  join [AnalitDB].[edu].[KG_Children_vers2] c
  on d.child_id = c.id
  join (
  -- ищем детей с одинаковыми именами, датами рождения, и данными свидетельств о рождении, при этом с разными id.
  -- начало выборки dbl
  SELECT distinct d1.[child_id], c1.name, c1.birthdate, certificate
  FROM [AnalitDB].[edu].[KG_Declarations_vers2] d1
  join [AnalitDB].[edu].[KG_Children_vers2] c1
  on d1.child_id = c1.id
  ) as dbl
  on d.child_id <> dbl.child_id and c.name = dbl.name and dbl.birthdate = c.birthdate and c.certificate = dbl.certificate
   where d.child_id in (
   SELECT distinct child_id
  FROM [AnalitDB].[edu].[KG_Placement] p
  join (
  SELECT [group_id]
      ,[date]
      ,[status]
  FROM [AnalitDB].[edu].[KG_GroupFields]
  where date = @date
  ) g
  on p.group_id = g.group_id
where g.status in (1) and p.date <= @date and (p.close_date is null or p.close_date > @date)
  )
  
  )
-- конец отбора "дублирующих" детей
-- из списка детей исключаем детей, которые есть в таблице  Placement
and child_id not in (
   SELECT distinct child_id
  FROM [AnalitDB].[edu].[KG_Placement] p
  join (
  SELECT [group_id]
      ,[date]
      ,[status]
  FROM [AnalitDB].[edu].[KG_GroupFields]
  where date = @date
  ) g
  on p.group_id = g.group_id
where g.status = 1 and p.date <= @date and (p.close_date is null or p.close_date > @date))
-- из списка исключаем детей, которые зачислены в плановые группы
and child_id not in (
SELECT child_id
  FROM [AnalitDB].[edu].[KG_Placement] p
  join (
  SELECT [group_id]
      ,[date]
      ,[status]
  FROM [AnalitDB].[edu].[KG_GroupFields]
  where date = @date
  ) g
  on p.group_id = g.group_id
where g.status = 2 and p.date <= @date and (p.close_date is null or p.close_date > @date)
--- Выше отобрали детей с статусом группы на назначенную дату — 2 — плановая.
--- Ниже, исключаем детей, у которых до назначенной даты, были статусы групп: Архивная или фактическая.
and child_id not in (
SELECT distinct child_id
  FROM [AnalitDB].[edu].[KG_Placement] p
  join (
  SELECT [group_id]
      ,[date]
      ,[status]
  FROM [AnalitDB].[edu].[KG_GroupFields]
  where date = @date
  ) g
  on p.group_id = g.group_id
where g.status in (0, 1) and p.date <= @date 
)
-- Отбираем детей, зачисленных в группы до 01 марта 2019 (до начала комплектования групп в прошлом году).
and p.date >= '2018-03-01'
)
and child_id not in (237228, 212898, 197120, 257122, 184625, 182082, 262774, 291495, 362858, 235319, 189043, 207717, 253283, 316184, 298552, 298412,
237245, 294673, 236273, 318222, 231019, 299938, 235334, 335638, 113659, 237237, 269112, 197120, 169854, 269490, 328429, 267806, 202000, 197120,
345941, 334271, 315962, 315695, 316411, 290748, 318694, 323954, 290850, 376485, 355898, 244632, 277423, 280917, 269112, 284159, 273100, 198439,
316411, 306186, 227616, 278996, 268377, 327430, 191537, 206474, 190667, 270873, 267764, 161474, 184373, 316909, 224758, 296618, 126856, 132084,
373447, 189041, 174170, 271000, 278303, 338320, 331744, 237409, 212015, 84535, 276545, 188604, 158681, 293541, 218476, 260570, 188812, 111180,
119533, 190887, 189161, 214452, 266634, 313306, 351038, 311289, 234115, 267041, 253283, 166201, 180621, 274758, 68568, 283534, 240975, 240976,
179560, 326350, 319848, 286884, 189043, 338454, 306186, 292843, 173382, 298552, 344379, 305747, 101357, 157583, 328199, 202000, 147514, 286808,
134574, 179889, 217980, 270873, 194522, 191537, 254093, 340548, 332851, 154882, 160564, 146600, 155659, 190667, 329216, 185281, 221364, 133426,
82172, 233742, 188670, 293627, 200620, 300388, 100290, 244632, 216750, 165464, 180280, 113696, 277291, 204574, 261465, 195490, 330470, 149023,
206474, 221624, 99193, 138301, 138209, 103452, 219689, 278660, 188722, 337733, 331596, 296509, 293678, 115198, 365044, 258421, 138129, 321094,
140911, 158731, 166320, 243731, 137628, 336483, 335966, 175314, 114599, 197120, 252849, 327430, 227616, 293618, 312525, 188521, 140180, 217291,
183481, 153136, 225953, 157480, 183121, 363067, 242697, 123315, 261117, 146655, 236914, 199495, 267831, 99101, 246639, 215998, 99989, 175991,
246073, 58690, 173364, 288374, 165229, 98861, 97280, 197858, 198423, 166547, 232187, 113703, 194833, 184163, 192995, 207177, 195549, 143013,
335709, 197864, 232200, 353104, 296569, 311950, 262719, 268244, 314363, 311940, 291510, 188192, 215192, 352821, 321847, 322748, 289654,
260171, 305239, 191265, 364272, 278962, 318664, 329853, 208539, 315971, 295510, 347655, 165225, 312483, 208364, 231804, 236984, 268827,
291524, 301288, 244117, 232614, 323878
)
and child_id not in (378493 /*2018 года рождения*/)
-- дети с некорректно указанным ДС желаемого зачисления
and child_id not in (211527, 224879, 235331, 238841, 241347, 247540, 259287, 263503, 267732, 267762, 268483, 268509, 268515, 275050,
275974, 277187, 283187, 285322, 285324, 285666, 287180, 290193, 295513, 298120, 311760, 320683, 322250, 322885, 323866, 328800, 330320,
330478, 331566, 332108, 332732, 336447, 337687, 338993, 338996, 339306, 345422, 347212, 349400, 349466, 351784,  355451, 355959,
358119, 359676, 359677, 361824, 361904, 381965, 382368
 ) 
 ) as main1



END
