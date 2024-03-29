USE [db_prospection]
GO
/****** Object:  StoredProcedure [dbo].[sp_getAnnonce]    Script Date: 03/08/2012 15:15:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER
procedure [dbo].[sp_getAnnonce]
  @id_prospecteur int
, @agence int
--, @trans char(1) = 'V'
as
set nocount on

declare
  @annonce int 
, @agence_old int
set @annonce = 0

	select top 1 @annonce = id from
	(
		select id, trans, 65534 as priority
		from anns
		where status = 'EN COURS'
		and prospecteur = @id_prospecteur 
		and Agence = @agence
		
		union all
		
		select id, trans, priority
		from Anns_Pending as ap
		where ap.Agence = @agence
		and ap.id not in
		(
			select annonce 
			from historique 
			where Prospecteur = @id_prospecteur
			and status not in ('EN COURS', 'NON ABOUTI', 'A RAPPELER')
		)
	) t
	--where Trans=@trans
	order by priority desc, trans desc
	
	if @annonce=0
	begin
		select @agence_old = @agence;
		exec @agence = dbo.sp_getAbonne @id_prospecteur;
		
		if @agence > 0 and @agence <> @agence_old
			select @annonce = dbo.fn_getAnnonce(@id_prospecteur, @agence);
	end
	
	if @annonce <> 0
	begin
		declare @date datetime
		select @date = '31/12/1999 23:59:59'
		select top 1 @date = DATE
		from historique
		where annonce = @annonce
		and status = 'EN COURS'
		order by date desc
		
		if(datediff(mi,@date,getdate())>=1)
		begin
			insert into Historique (Prospecteur, Abonne, Annonce)
			values (@id_prospecteur, @agence, @annonce);
		end
	end

	select @annonce as annonce;




