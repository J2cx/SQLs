USE [db_prospection]
GO
/****** Object:  UserDefinedFunction [dbo].[statsPrp]    Script Date: 03/08/2012 15:14:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER
function [dbo].[statsPrp]
(
	@id_prospecteur int
	, @dateStart datetime
	, @dateEnd datetime
)
returns @tbStatsPrp table
(
	Prospecteur int Not null
	, Prenom varchar(50) Not null
	, DateStart datetime not null
	, DateEnd datetime not null
	, nbAgence int not null
	, nbAnnonce int not null
	, nbRDV int not null
	, nbRAP int not null
	, nbEnCours int not null
	, nbNonAbouti int not null
	, nbRefus int not null
	, RDVinAnn DECIMAL(10,2) not null
	, RDVinTous DECIMAL(10,2) not null
	, RDVdifMoyen DECIMAL(10,2) not null
	, NAinAnn DECIMAL(10,2) not null
	, RefusinAnn DECIMAL(10,2) not null
	, nbRDVConteste int not null
	, ConinRDV DECIMAL(10,2) not null
	, ConinTous DECIMAL(10,2) not null
	, CondifMoyen DECIMAL(10,2) not null
)
as
begin

	declare @nbAgence int = 0
	, @Pre varchar(50) = ''
	, @nbAnnonce int = 0
	, @nbRDV int = 0
	, @nbRAP int = 0
	, @nbEnCours int = 0
	, @nbNonAbouti int = 0
	, @nbRefus int = 0
	, @RDVinAnn DECIMAL(10,2) = 0
	, @RDVinTous DECIMAL(10,2) = 0
	, @RDVdifMoyen DECIMAL(10,2) = 0
	, @NAinAnn DECIMAL(10,2)  = 0
	, @RefusinAnn DECIMAL(10,2) = 0
	, @nbRDVConteste int = 0
	, @ConinRDV DECIMAL(10,2) = 0
	, @ConinTous DECIMAL(10,2) = 0
	, @CondifMoyen DECIMAL(10,2) = 0
	
	, @nbRDVTous int = 0
	, @nbConTous int = 0
	, @nbProspecteur int = 0 
	--select * from historique
	--insert into historique (prospecteur, abonne, annonce)
	--values (5, 22222, 55555)
	--declare @dateStart datetime = '03/02/1999'
	--, @dateEnd datetime = '24/02/2012'
	--, @id_prospecteur int  = 2
	
	select @Pre = pre from prospecteurs
	where id = @id_prospecteur
	
	select @nbAgence = count(distinct abonne) 
	from historique 
	where prospecteur = @id_prospecteur 
	and date between @dateStart and @dateEnd
	group by prospecteur ;

	select @nbAnnonce = count(distinct annonce) 
	from historique where prospecteur = @id_prospecteur
	and date between @dateStart and @dateEnd
	group by prospecteur ;

	declare @tbtemp table
	(
		id int
		, date datetime
		, prospecteur int
		, abonne int
		, annonce int
		, status varchar(50)
	)
	
	if(@nbAnnonce > 0)
	begin
	
		declare @iloop int=1
		
		while @iloop <= @nbAnnonce
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
			--and prospecteur = @id_prospecteur	
			order by date desc	
			
			set @iloop=@iloop+1;
		end	
		
				
		select @nbRDV = COUNT (*) from @tbtemp where status='RENDEZ-VOUS' and prospecteur = @id_prospecteur	
		select @nbRAP = COUNT (*) from @tbtemp where status='A RAPPELER' and prospecteur = @id_prospecteur	
		select @nbEnCours = COUNT (*) from @tbtemp where status='EN COURS' and prospecteur = @id_prospecteur	
		select @nbNonAbouti = COUNT (*) from @tbtemp where status='NON ABOUTI' and prospecteur = @id_prospecteur	
		select @nbRefus = COUNT (*) from @tbtemp where status='REFUS' and prospecteur = @id_prospecteur	
		
		select @nbRDVTous = COUNT (*) from @tbtemp where status='RENDEZ-VOUS'
		select @nbProspecteur = Count(*) from Prospecteurs
		
		SELECT @RDVinAnn = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRDV) /
													CONVERT(DECIMAL(10,2),@nbAnnonce))
		if(@nbRDVTous > 0)
		begin
			SELECT @RDVinTous = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRDV) /
														CONVERT(DECIMAL(10,2),@nbRDVTous))
			SELECT @RDVdifMoyen = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRDV) /
														(CONVERT(DECIMAL(10,2),CONVERT(DECIMAL(10,2),@nbRDVTous) /
																				CONVERT(DECIMAL(10,2),@nbProspecteur))))	
		end								
		else
		begin
			SELECT @RDVinTous = 0
			SELECT @RDVdifMoyen = 0
		end
															
		SELECT @NAinAnn = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbNonAbouti) /
													CONVERT(DECIMAL(10,2),@nbAnnonce))
		SELECT @RefusinAnn = CONVERT (DECIMAL(10,2), CONVERT(DECIMAL(10,2),@nbRefus) /
													CONVERT(DECIMAL(10,2),@nbAnnonce))
													
		select @nbConTous = count(*) from RDV 
		where RDVstatus in ( 'ANNULE','SUPPRIME')
		and date between @dateStart and @dateEnd										
													
		
		select @nbRDVConteste = count(*) from RDV 
		where RDVstatus in ( 'ANNULE','SUPPRIME')
		and prospecteur = @id_prospecteur 
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
																					CONVERT(DECIMAL(10,2),@nbProspecteur))))	
		end
		else
		begin
			SELECT @ConinTous = 0
			select @CondifMoyen = 0
		end
			

			
	end
	
	insert @tbStatsPrp
	select @id_prospecteur, @Pre, @dateStart, @dateEnd, @nbAgence, @nbAnnonce
			, @nbRDV, @nbRAP, @nbEnCours, @nbNonAbouti, @nbRefus
			, @RDVinAnn, @RDVinTous, @RDVdifMoyen, @NAinAnn, @RefusinAnn
			, @nbRDVConteste, @ConinRDV, @ConinTous, @CondifMoyen

	return;
end

