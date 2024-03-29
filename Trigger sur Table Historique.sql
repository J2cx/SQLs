USE [db_prospection]
GO
/****** Object:  Trigger [dbo].[TRG_Histo_Insert]    Script Date: 03/08/2012 15:09:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER
trigger [dbo].[TRG_Histo_Insert]
on [dbo].[Historique]
AFTER INSERT
as
set nocount on

declare
  @agence int
, @annonce int
, @status varchar(50)
, @prospecteur int
, @aux int
, @trans char(1)

--select top 10 * from anns

select
  @agence = A.Abonne
, @annonce= A.Annonce
, @status = A.status
, @prospecteur = A.prospecteur
, @aux = B.aux
, @trans = B.trans
from inserted as A
join anns as B
on A.annonce = B.id

update db_directmandat..prospection set
  Status = @status
, Prospecteur = @prospecteur
where Agence=@agence
and Aux=@aux and trans = @trans

/*
select top 10 * from db_directmandat..prospection
select top 10 * from anns
select top 10 * from historique
insert into historique(prospecteur, abonne, annonce, status) values(1, 12625, 3, 'EN COURS')
*/