USE [db_prospection]
GO

/****** Object:  View [dbo].[Anns_Pending]    Script Date: 03/08/2012 15:11:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER
view [dbo].[Anns_Pending]
as

select *, dbo.defPrio(agence) as priority
from
(
	select * from Anns
	where date > dateAdd(day, -8, getDate())
	and status = 'EN ATTENTE'
	
	union all
	
	select * from Anns
	where date > dateAdd(day, -3, getDate())
	and status = 'NON ABOUTI'
	and
	(
		select count(id) from historique where annonce = Anns.id and status = 'NON ABOUTI'
		and date between dateAdd(day, -2, getDate()) and getDate()
	) < 4
	and
	(
		select count(id) from historique where annonce = Anns.id and status = 'NON ABOUTI'
		and convert(varchar(10), date, 103)  = convert(varchar(10), getDate(), 103)
	) < 2
	
	union all
	
	select * from Anns
	where status = 'A RAPPELER'
	
	union all
	
	select * from Anns
	where status = 'REFUS'
	and 
	(
		select count(*) from historique where status='REFUS' and annonce = Anns.id
	)<2

	
) t
where agence in ( select abo from abonnes )
and done = 0


GO


