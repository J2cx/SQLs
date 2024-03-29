USE [db_prospection]
GO
/****** Object:  StoredProcedure [dbo].[sp_getAbonne]    Script Date: 03/08/2012 15:15:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER
procedure [dbo].[sp_getAbonne]
  @id_prospecteur int
--, @trans char(1) = 'V'
as
set nocount on

declare @agence int
, @nb_locks int
, @nb_annonces int
--, @id_prospecteur int
select @agence=0
--select @id_prospecteur =2

	select @nb_locks=count(*) from abo_locks where Prospecteur = @id_prospecteur
	if(@nb_locks=1)
	begin
		select top 1 @agence = Abonne from abo_locks where Prospecteur = @id_prospecteur;
		
		select @nb_annonces=count(*)
		from Anns_Pending as ap
		where ap.id not in 
		(
			select 
			annonce
			--*
			from historique 
			where Prospecteur=@id_prospecteur
			and status not in ('NON ABOUTI','EN COURS','A RAPPELER')
		)
		and ap.agence=@agence;
		
		if(@nb_annonces>0)
		begin
			select @agence as agence
			return;	
		end
	end

	delete from abo_locks where Prospecteur=@id_prospecteur;

	select top 1 @agence=Agence from
	(
		select *, 65534 as priority from anns
		where status = 'en cours' and prospecteur = 
		@id_prospecteur
		union all
		select *
		from Anns_Pending as ap
		where ap.id not in 
		(
			select 
			annonce
			--*
			from historique 
			where Prospecteur=@id_prospecteur
			and status not in ('NON ABOUTI','EN COURS','A RAPPELER')
			
		)
	) t
		where t.Agence not in
		(
			select Abonne from Abo_Locks
			where 
			(
				select Count(Abonne) from Abo_Locks 
				where Abonne=t.Agence
				group by Abonne
			)
			>=
			(
				select valeur from db_directannonces.dbo.CLIENTS_AUX_VAL(t.Agence) 
				where  clef ='prp_nbProspecteurs'
			)
		)
		--and Trans=@trans
	order by priority desc, trans desc
	
	if(@agence<>0)
		insert into dbo.Abo_Locks 
				(Abonne,Prospecteur)
		values	(@agence,@id_prospecteur);
	
select @agence as agence
