USE [db_prospection]
GO
/****** Object:  UserDefinedFunction [dbo].[statsAbo]    Script Date: 03/08/2012 15:13:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER
function [dbo].[statsAbo]
(
	@id_agence int
	, @dateStart datetime
	, @dateEnd datetime
)
returns @tbStatsPrp table
(
	id_agence int Not null
	, DateStart datetime not null
	, DateEnd datetime not null
	, nbAnnAFaire int Not null
	, nbAnnTraite int Not NUll
	, nbRDV int not null
	, nbRAP int not null
	, nbEnCours int not null
	, nbNonAbouti int not null
	, nbRefus int not null
	, RDVinAnn DECIMAL(10,2) not null
	, RDVinTous DECIMAL(10,2) not null
	, RDVdifMoyen DECIMAL(10,2) not null
	, nbRDVConteste int not null
	, ConinRDV DECIMAL(10,2) not null
	, ConinTous DECIMAL(10,2) not null
	, CondifMoyen DECIMAL(10,2) not null
)
as
begin
	
	declare 
	  @nbAnnAFaire int = 0
	, @nbAnnTraite int = 0
	, @nbRDV int = 0
	, @nbRAP int = 0
	, @nbEnCours int = 0
	, @nbNonAbouti int = 0
	, @nbRefus int = 0
	, @RDVinAnn DECIMAL(10,2) = 0
	, @RDVinTous DECIMAL(10,2) = 0
	, @RDVdifMoyen DECIMAL(10,2) = 0
	, @nbRDVConteste int = 0
	, @ConinRDV DECIMAL(10,2) = 0
	, @ConinTous DECIMAL(10,2) = 0
	, @CondifMoyen DECIMAL(10,2) = 0
	
	, @nbRDVTous int = 0
	, @nbConTous int = 0
	, @nbAgence int = 0 
	
	--select * from anns
	--select * from anns 
	--where agence = 12625
	
	select @nbAnnAFaire = count(*) 
	from anns_pending
	where agence = @id_agence
	
	select @nbAnnTraite = count(distinct annonce)
	from historique 
	where abonne = @id_agence
	and date between @dateStart and @dateEnd
	
	if(@nbAnnTraite>0)
	begin
		declare @tbtemp table
		(
			id int
			, date datetime
			, prospecteur int
			, abonne int
			, annonce int
			, status varchar(50)
		)
		
		declare @iloop int=1
		
		while @iloop <= 11
		begin
			insert @tbtemp
			select top 1 id, date, prospecteur, abonne, annonce, status from historique as h1
			where h1.annonce =
			(
				select annonce from
				(
					select annonce,ROW_NUMBER() OVER (ORDER BY annonce asc) AS 'RowNumber'
					FROM 
					(
						select 
						distinct annonce 
						from historique
					)t
				)tb
				where RowNumber = @iloop
			)
			and date between @dateStart and @dateEnd
			--and abonne = @id_agence	
			order by date desc	
			
			set @iloop=@iloop+1;
		end	
		
		--select * from @tbtemp
		
		select @nbRDV = COUNT (*) from @tbtemp where status='RENDEZ-VOUS' and abonne = @id_agence	
		select @nbRAP = COUNT (*) from @tbtemp where status='A RAPPELER' and abonne = @id_agence	
		select @nbEnCours = COUNT (*) from @tbtemp where status='EN COURS' and abonne = @id_agence	
		select @nbNonAbouti = COUNT (*) from @tbtemp where status='NON ABOUTI' and abonne = @id_agence	
		select @nbRefus = COUNT (*) from @tbtemp where status='REFUS' and abonne = @id_agence
		
		select @nbRDVTous = COUNT (*) from @tbtemp where status='RDV'
		select @nbAgence = Count(*) from abonnes
						
		SELECT @RDVinAnn = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRDV) /
													CONVERT(DECIMAL(10,2),@nbAnnTraite))
		if(@nbRDVTous > 0)
		begin
			SELECT @RDVinTous = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRDV) /
														CONVERT(DECIMAL(10,2),@nbRDVTous))
			SELECT @RDVdifMoyen = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRDV) /
														(CONVERT(DECIMAL(10,2),CONVERT(DECIMAL(10,2),@nbRDVTous) /
																				CONVERT(DECIMAL(10,2),@nbAgence))))	
		end								
		else
		begin
			SELECT @RDVinTous = 0
			SELECT @RDVdifMoyen = 0
		end
		
		select @nbConTous = count(*) from RDV 
		where RDVstatus in ( 'ANNULE','SUPPRIME')
		and date between @dateStart and @dateEnd										
													
		--select * from rdv
		select @nbRDVConteste = count(*) from RDV 
		where RDVstatus in ( 'ANNULE','SUPPRIME')
		and agence = @id_agence 
		and date between @dateStart and @dateEnd
		
		if(@nbRDV >0)
			SELECT @ConinRDV  = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRDVConteste) /
														CONVERT(DECIMAL(10,2),@nbRDV))
		else
			SELECT @ConinRDV =0
			
		if(@nbConTous >0)
		begin
			SELECT @ConinTous  = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRDVConteste) /
															CONVERT(DECIMAL(10,2),@nbConTous))
			SELECT @CondifMoyen = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRDVConteste) /
															(CONVERT(DECIMAL(10,2),CONVERT(DECIMAL(10,2),@nbConTous) /
																					CONVERT(DECIMAL(10,2),@nbAgence))))	
		end
		else
		begin
			SELECT @ConinTous = 0
			select @CondifMoyen = 0
		end
													
	
	end
	
	insert @tbStatsPrp
	select @id_agence, @dateStart, @dateEnd,  @nbAnnAFaire, @nbAnnTraite
			, @nbRDV, @nbRAP, @nbEnCours, @nbNonAbouti, @nbRefus
			, @RDVinAnn,  @RDVinTous, @RDVdifMoyen
			, @nbRDVConteste, @ConinRDV, @ConinTous, @CondifMoyen

	return;
end


